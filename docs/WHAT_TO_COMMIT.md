# 仓库应存放内容（已按照此文件编写.gitignore）

建议**提交到 GitHub 仓库**的目录：
- `unitree_sim_isaaclab/`（源码快照，含你的修复）
- `xr_teleoperate/`（源码快照，含你的修复）
- `unitree_sdk2_python/`（源码快照）
- `docs/`
- `scripts/`
- `patches/`
- `env/`
- `ENV_AUDIT_AND_RUNBOOK_2026-04-08.md`
- `README.md`

建议**不要提交**：
- `unitree_sim_isaaclab/assets/` 下载资产（体积很大，复现时用 `. fetch_assets.sh` 获取）
- `miniforge3/`（本地 conda 安装目录）
- `IsaacLab/`（由脚本拉取，且体积大）
- `cyclonedds/`（本地构建/依赖目录）
- 任意 `__pycache__/`、`*.pyc`
- 运行日志、录制数据、模型缓存
- 私钥文件（如 `key.pem`）
