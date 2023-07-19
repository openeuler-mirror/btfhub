# 预构建 BTF 支持版本

openEuler BTF 管理基础设施提供的预构建内核 BTF 如以下表格所示。表格中的标记含义（同[原 BTFHub 支持版本文档](https://github.com/aquasecurity/btfhub/blob/main/docs/supported-distros.md)）：

- BPF：内核提供对 eBPF 程序支持；
- BTF：内核构建时启用 `DEBUG_INFO_BTF` 选项，自带 BTF 信息；
- HUB：openEuler BTF 管理基础设施为其提供预构建 BTF。

## openEuler

目前 openEuler BTF 管理基础设施支持所有还在生命周期内的 openEuler 系统版本（可见[各版本计划 EOL](https://www.openeuler.org/zh/download/archive/)），为所有未启用 `DEBUG_INFO_BTF` 选项的内核预构建 BTF。

### openEuler 20.03

| openEuler 版本 | 内核版本 | BPF | BTF | HUB |
| ------------- | ------- | --- | --- | --- |
| 20.03 LTS SP3 | 4.19.90-2112.8.0.0131.oe1 | Y | - | Y |

### openEuler 22.03

| openEuler 版本 | 内核版本 | BPF | BTF | HUB |
| ------------- | ------- | --- | --- | --- |
| 22.03 LTS | 5.10.0-60.18.0.50.oe2203 | Y | Y | - |
| 22.03 LTS SP1 | 5.10.0-136.12.0.86.oe2203sp1 | Y | Y | - |
| 22.03 LTS SP2 | 5.10.0-153.12.0.92.oe2203sp2 | Y | Y | - |

### openEuler 23.03

| openEuler 版本 | 内核版本 | BPF | BTF | HUB |
| ------------- | ------- | --- | --- | --- |
| 23.03 | 6.1.19-7.0.0.17.oe2303 | Y | Y | - |

## 其他发行版

openEuler BTF 管理基础设施目前未提供其他发行版的预构建内核 BTF。原 [BTFHub](https://github.com/aquasecurity/btfhub) 项目提供了 Debian、Ubuntu、Fedora、CentOS 等常见发行版的预构建 BTF；openEuler BTF 管理基础设施提供的预构建 BTF 文件格式、目录结构与原 BTFHub Archive 提供的预构建 BTF 相同，可以安全地混合使用，以同时兼容 openEuler 与其他常见发行版。
