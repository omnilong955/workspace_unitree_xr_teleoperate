# workspace_unitree_xr_teleoperate

本仓库用于在 Ubuntu 22.04 + RTX 4090 上复现：
- `unitree_sim_isaaclab`（Isaac Sim 4.5）
- `xr_teleoperate`

本仓库已包含**可运行源码快照**：
- `unitree_sim_isaaclab/`（含本地 DDS 网卡绑定修复）
- `xr_teleoperate/`（含录制稳定性修复）
- `unitree_sdk2_python/`

注意：`unitree_sim_isaaclab/assets/` 大体积资产未入库，需按文档执行 `. fetch_assets.sh` 下载。

详细环境版本、修改记录与启动说明见：
- `ENV_AUDIT_AND_RUNBOOK_2026-04-08.md`
- `docs/REPRODUCE.md`

## 目录说明
- `unitree_sim_isaaclab/`：仿真源码（已包含本地修复）
- `xr_teleoperate/`：遥操作源码（已包含本地修复）
- `unitree_sdk2_python/`：DDS Python SDK
- `patches/`：本地源码改动的 patch 留档
- `scripts/`：复现辅助脚本（网卡、证书、启动命令、numba hotfix）
- `env/`：环境变量样例

## 快速开始
按 `docs/REPRODUCE.md` 执行即可。
