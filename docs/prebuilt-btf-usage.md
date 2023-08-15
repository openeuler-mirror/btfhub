# 预构建 BTF 使用说明

openEuler BTF 管理基础设施目前为所有仍受 openEuler 官方支持的、未携带 BTF 信息的内核版本提供了预构建的 BTF（详见[支持版本](supported-versions.md)文档）。利用这些预构建 BTF，可以将目标平台 BTF 裁剪后随 eBPF 程序一同分发，解决旧版内核未携带 BTF 信息从而无法使用 CO-RE 特性的问题。

假设目前已经能够成功构建 eBPF 程序及其对应的用户态控制程序，目录结构如下：

```
├── program.bpf.c # eBPF 程序
├── program.bpf.o # eBPF 程序构建产物
├── program.c # 用户态控制程序
└── program # 用户态控制程序构建产物
```

1. 克隆 BTF 归档仓（[`openeuler/btfhub-archive` 仓库](https://gitee.com/openeuler/btfhub-archive)）：

   ```shell
   git clone --depth=1 https://gitee.com/openeuler/btfhub-archive.git
   ```

2. 找到目标平台内核 BTF，并根据 eBPF 程序裁剪（以 openEuler 20.03 LTS SP3 为例）：

   ```shell
   DISTRO=openEuler # os-release ID
   DISTRO_VERSION=20.03 # os-release VERSION_ID
   ARCH=x86_64 # uname -m
   KERNEL_VERSION=4.19.90-2112.8.0.0131.oe1.x86_64 # uname -r

   tar xvJf "btfhub-archive/${DISTRO}/${DISTRO_VERSION}/${ARCH}/${KERNEL_VERSION}.btf.tar.xz"
   bpftool gen min_core_btf "${KERNEL_VERSION}.btf" program.btf program.bpf.o
   ```

   裁剪后 BTF 文件（`program.btf`）中仅含指定 eBPF 程序（`program.bpf.o`）中所需要的信息，因此只能用于该 eBPF 程序。

3. 更改用户态控制程序，设置 `struct bpf_object_open_opts` 中 `btf_custom_path` 字段（[参考](https://github.com/libbpf/libbpf/blob/05f94ddbb837f5f4b3161e341eed21be307eaa04/src/libbpf.h#L136-L142)），以使 libbpf 使用指定的 BTF 而非系统自带 BTF：

   ```diff
   + 	LIBBPF_OPTS(bpf_object_open_opts, open_opts)
   + 	open_opts.btf_custom_path = "program.btf";
   +
   - 	struct bpf_object *bpf = bpf_object__open("program.bpf.o");
   + 	struct bpf_object *bpf = bpf_object__open_file("program.bpf.o", &open_opts);
   ```

4. 将裁剪后的 BTF 文件（`program.btf`）随原构建产物一同分发。

## 使用示例 / 模板

### 针对单个目标平台

本仓库 [`examples`](../examples/) 目录以 [libbpf-bootstrap](https://github.com/libbpf/libbpf-bootstrap) 为基础，封装上述裁剪 BTF 的步骤，提供了一个简单示例。

```shell
# 克隆本仓库与 BTF 归档仓
git clone --recurse-submodules https://gitee.com/openeuler/btfhub.git
git clone --depth=1 https://gitee.com/openeuler/btfhub-archive.git

# 构建 eBPF 应用与裁剪 BTF（使用 EXTRA_BTF_PACKAGE 指定 .btf.tar.xz 文件）
cd btfhub/examples/src
make EXTRA_BTF_PACKAGE=../../../btfhub-archive/openEuler/20.03/x86_64/4.19.90-2112.8.0.0131.oe1.x86_64.btf.tar.xz
```

### 针对多个目标平台

如需对多个目标平台同时生成裁剪后 BTF 并随应用程序分发，建议参考 eunomia-bpf 项目中的 [bpf-compatible](https://github.com/eunomia-bpf/bpf-compatible)，其定义了一套组织不同平台 BTF 的格式并提供工具脚本与工具库以生成与解析这种格式。

使用 bpf-compatible 中的工具脚本 [`btfgen`](https://github.com/eunomia-bpf/bpf-compatible/blob/main/script/btfgen) 时，可以将 openEuler 提供的 BTF 归档仓添加到 `BTFHUB_REPO` 环境变量，以在其默认支持的常见发行版之外，提供对 openEuler 的兼容性支持。如可以修改其项目模板中的 [Makefile](https://github.com/eunomia-bpf/bpf-compatible/blob/main/example/c/Makefile)：

```diff
  $(OUTPUT)/btfhub-cache:
- 	BTFHUB_REPO=https://github.com/eunomia-bpf/btfhub-archive \
+ 	BTFHUB_REPO=https://github.com/eunomia-bpf/btfhub-archive,https://gitee.com/openeuler/btfhub-archive.git \
  	BTFHUB_CACHE=$(OUTPUT)/btfhub-cache \
  	../../script/btfgen fetch
```
