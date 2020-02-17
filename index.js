const http = require('http');
const https = require('https');
const url = require('url');
const pg = require('pg');

// Perform an HTTPS request
//
// reqUrl: string of url
// body: Unspecified or NULL for GET, specify for POST
// headers: Object of header
//
// Returns: A Promise, resolving to an Object of:
//  status: The status code
//  headers: Object of headers
//  body: string of response
function request(reqUrl, body = null, headers = null) {
    if (headers === null) {
        headers = {};
    }

    if (body !== null) {
        body = Buffer.from(body);
        headers['Content-Length'] = body.length;
    }

    const options = Object.assign({}, url.parse(reqUrl), {
        method: body === null ? 'GET' : 'POST',
        headers
    });

    return new Promise((resolve, reject) => {
        const req = https.request(
            options,
            (res) => {
                const chunks = [];
                let len = 0;

                res.on('data', (chunk) => {
                    chunks.push(chunk);
                    len += chunk.length;
                });

                res.on('end', () => {
                    const body = Buffer.concat(chunks, len).toString();
                    resolve({
                        status: res.statusCode,
                        headers: res.headers,
                        body
                    });
                });

                res.on('error', (e) => { reject(e); });
            });

        req.on('error', (e) => { reject(e); });

        if (body !== null) {
            req.write(body);
        }

        req.end();
    });
}

// Optionally use token for GitHub, depending on env GITHUB_TOKEN
// Returns: An Object of headers,
function githubHeader() {
    if (process.env.GITHUB_TOKEN) {
        return {
            'Authorization': `token ${process.env.GITHUB_TOKEN}`
        };
    } else {
        return {}
    }
}

async function doUpdate(client) {
    const readData = async () => {
        const res = await client.query('select data from bot_state limit 1');

        if (res.rows.length > 0)
            return JSON.parse(res.rows[0].data);
        else
            return null;
    };

    const writeData = async (data) => {
        await client.query('BEGIN');

        await client.query('delete from bot_state');
        await client.query('insert into bot_state (data) values ($1)', [ JSON.stringify(data) ]);

        await client.query('COMMIT');
    };

    const state = await readData();

    const oldsha = state === null ? null : state.sha;
    const etagHeader = state === null ? {} : { 'If-None-Match': state.etag };

    const github = await request(
        'https://api.github.com/repos/LearningOS/os-lectures/branches/master',
        null,
        {
            'User-Agent': 'dramforever',
            ... githubHeader(),
            ... etagHeader
        });

    if (github.status === 304)
        return { sha: oldsha, updated: false };

    const newsha = JSON.parse(github.body).commit.sha;

    if (oldsha === newsha)
        return { sha: oldsha, updated: false };

    request(
        `https://circleci.com/api/v1.1/project/github/dramforever/os-lectures-build?circle-token=${process.env.CIRCLECI_TOKEN}`,
        '{}'
    );

    await writeData({
        sha: newsha,
        etag: github.headers.etag
    });

    return { sha: newsha, updated: true };
}

async function handle(request) {
    const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
    try {
        await client.connect();

        if (request.url === `/update/${process.env.BOT_SECRET}`
            && request.method === 'POST') {
            const result = await doUpdate(client);
            return result;
        } else {
            throw 'Bad request'
        }
    } finally {
        await client.end();
    }
}

function topLevel(request, response) {
    handle(request)
        .then((res) => {
            if (typeof res === 'object') {
                response.writeHead(200, { 'Content-Type': 'application/json' });
                response.end(JSON.stringify({
                    status: 'success',
                    ... res
                }));
            }
        })
        .catch((err) => {
            console.log(err);
            response.writeHead(400, { 'Content-Type': 'text/plain' });
            response.end(JSON.stringify({
                status: 'error',
                error: err.toString()
            }));
        });
}

async function setupDatabase() {
    const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
    try {
        await client.connect();

        await client.query(`
            create table if not exists bot_state (
                data text not null
            );`);
    } finally {
        await client.end();
    }
}

setupDatabase()
    .then(() => {
        const server = http.createServer(topLevel);
        const port = process.env.PORT || 5000;
        server.listen(port);
    })
    .catch(err => {
        console.error(err);
    })
