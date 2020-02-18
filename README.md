# os-lectures-build

https://github.com/LearningOS/os-lectures 讲义的自动构建

## 下载

https://github.com/dramforever/os-lectures-build/releases

## 包含组件

- 构建所用的 Nix 表达式 `default.nix` 及依赖的文件 `repo.json`、`handout-mode.patch`、`Makefile`
    - 完整描述了整个构建过程，你可能看不懂 = =，但本质和原 repo 是一样的
    - 用的是 TeX Live 2019
    - `repo.json`：用 `nix-prefech-git` 生成的锁定版本的仓库信息
        ```console
        $ nix-prefetch-git --url "https://github.com/LearningOS/os-lectures.git" > repo.json
        ```
    - `handout-mode.patch`：使用 Beamer 的 handout 模式，关闭“动画”。
    - `Makefile`：使用 `latexmk` 自动处理构建时要求运行 `xelated` 多次的情况，使用 `pdftk` 将 PDF 文件合并
- `Dockerfile` 和 `Dockerfile.1` 缓存构建依赖
- `.circleci/config.yml` CircleCI 配置文件，调用构建，上传 release 文件。
- `index.js`、`package.json`、`Procfile`：自动更新 Bot，白嫖 Heroku
    - 向 `/update/$BOT_SECRET` 发送任意 `POST` 请求触发一次更新，自动检查是否最新 commit 变动，若有在 CircleCI 触发一次 build
    - 环境变量：
        - `BOT_SECRET` 字符串，用法如前所述
        - `DATABASE_URL` 字符串，PostgreSQL 数据库 connection string
        - `CIRCLECI_TOKEN` 字符串
        - `GITHUB_TOKEN` 字符串，可选

## TODO

- PDF 目录
- 有些 hard-coded 的部分可以改进
