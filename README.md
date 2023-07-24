# btfhub

## 介绍

openEuler BTF 管理基础设施为 openEuler 系统多个版本内核提供预构建的 BTF。预构建 BTF 可以用于较旧版本、未原生提供 BTF 信息的内核，保障 eBPF CO-RE 特性正常运行，以为部署的 eBPF 程序提供兼容性支持。openEuler BTF 管理基础设施基于原有 [BTFHub](https://github.com/aquasecurity/btfhub) 项目构建，所构建的 BTF 与原 BTFHub 格式一致，较原 BTFHub 添加了对 openEuler 发行版的支持。

更详细的介绍请参见[项目介绍文档](docs/project-introduction.md)。

## 使用说明

### 使用 BTF

openEuler BTF 管理基础设施 BTF 资源归档仓位于 [`openeuler/btfhub-archive` 仓库](https://gitee.com/openeuler/btfhub-archive)，提供了为 openEuler 系统内核预构建的 BTF 文件，可供直接下载使用。本仓库仅包含 BTF 构建工具源码以及 openEuler BTF 管理基础设施相关配置、文档。

预构建的 BTF 所覆盖的 openEuler 系统版本可参见[支持版本](docs/supported-versions.md)文档。

### 构建 BTF

利用本仓库提供的工具构建 BTF，所需要的工具版本包括：

- Go，最低版本 1.19
- pahole，最低版本 1.22

构建 BTF 的步骤如下：

1. 克隆本仓库与 BTF 资源归档仓；

   ```bash
   git clone https://gitee.com/openeuler/btfhub.git
   git clone https://gitee.com/openeuler/btfhub-archive.git
   ```

2. 构建 `btfhub` 工具；

   ```bash
   cd btfhub
   make
   ```

3. 构建 BTF。

   ```bash
   make bring # 从本地归档仓拉取存量 BTF
   ./btfhub -distro "<发行版名称，如 openEuler>"
   make take # 将 BTF 推送至本地归档仓
   ```

构建完成后，本地归档仓（`btfhub-archive` 仓库）将包含最新构建的 BTF 文件，可直接推送至远端供用户下载使用。
