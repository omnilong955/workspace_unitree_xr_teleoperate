# 复现步骤（Ubuntu 22.04 + RTX 4090）

## 0. 克隆你的仓库
```bash
git clone https://github.com/omnilong955/workspace_unitree_xr_teleoperate.git
cd workspace_unitree_xr_teleoperate
```

## 1. 前置检查
```bash
nvidia-smi
```
期望看到 RTX 4090 和可用驱动。

## 2. 安装/准备 Conda（Miniforge）
如果本机没有 conda，安装 Miniforge（示例）：
```bash
wget -O Miniforge3.sh https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash Miniforge3.sh -b -p "$PWD/miniforge3"
source "$PWD/miniforge3/etc/profile.d/conda.sh"
```
如果已有 conda，只需确保终端可用 `conda` 命令。

## 3. 安装 unitree_sim_isaaclab（Isaac Sim 4.5）
```bash
source ./miniforge3/etc/profile.d/conda.sh
cd unitree_sim_isaaclab
chmod +x auto_setup_env.sh
bash auto_setup_env.sh 4.5 unitree_sim_env
```

安装 LFS 并下载资产：
```bash
sudo apt update
sudo apt install -y git-lfs
cd unitree_sim_isaaclab
. fetch_assets.sh
```

应用 numba 兼容热修（必须）：
```bash
source ./miniforge3/etc/profile.d/conda.sh
conda activate unitree_sim_env
bash ../scripts/apply_numba_coverage_hotfix.sh
```

## 4. 安装 xr_teleoperate 环境（tv）
```bash
source ./miniforge3/etc/profile.d/conda.sh
conda create -n tv python=3.10 pinocchio=3.1.0 numpy=1.26.4 -c conda-forge -y
conda activate tv

cd xr_teleoperate

# 安装依赖（官方 requirements）
pip install -r requirements.txt

# 安装 teleop 子模块
cd teleop/teleimager && pip install -e . --no-deps
cd ../televuer && pip install -e .

# 安装 dex-retargeting（手部重定向）
cd ../robot_control/dex-retargeting && pip install -e . --no-deps

# 安装 unitree sdk python（editable）
cd ../../../unitree_sdk2_python && pip install -e .
```

如果遇到 `pinocchio`/`GLIBCXX` 问题，运行前加：
```bash
export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:${LD_LIBRARY_PATH:-}"
```

## 5. 生成证书（按当前主机 IP）
先查 IP：
```bash
bash scripts/print_network_info.sh
```

用实际 IP 生成（示例）：
```bash
bash scripts/generate_televuer_cert.sh 192.168.137.134
```

## 6. 启动联调（Dex3 手势）
终端 A：
```bash
source ./miniforge3/etc/profile.d/conda.sh
conda activate unitree_sim_env
cd unitree_sim_isaaclab

export UNITREE_DDS_NETWORK_INTERFACE=wlx6c1ff7877849
python -u sim_main.py \
  --device cpu \
  --enable_cameras \
  --task Isaac-PickPlace-Cylinder-G129-Dex3-Joint \
  --enable_dex3_dds \
  --robot_type g129
```

终端 B：
```bash
source ./miniforge3/etc/profile.d/conda.sh
conda activate tv
export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:${LD_LIBRARY_PATH:-}"
cd xr_teleoperate/teleop

python -u teleop_hand_and_arm.py \
  --input-mode hand \
  --arm G1_29 \
  --ee dex3 \
  --sim \
  --record \
  --img-server-ip 192.168.137.134 \
  --network-interface wlx6c1ff7877849
```

XR 端：
1. `https://<HOST_IP>:60001`（若 webrtc 开启，先信任证书）
2. `https://<HOST_IP>:8012/?ws=wss://<HOST_IP>:8012`
3. 点击 `Virtual Reality`
4. 终端按 `r` 开始同步

## 7. 启动联调（Dex1 手柄扳机）
终端 A（仿真必须换 dex1 task）：
```bash
source ./miniforge3/etc/profile.d/conda.sh
conda activate unitree_sim_env
cd unitree_sim_isaaclab

export UNITREE_DDS_NETWORK_INTERFACE=wlx6c1ff7877849
python -u sim_main.py \
  --device cpu \
  --enable_cameras \
  --task Isaac-PickPlace-Cylinder-G129-Dex1-Joint \
  --enable_dex1_dds \
  --robot_type g129
```

终端 B：
```bash
source ./miniforge3/etc/profile.d/conda.sh
conda activate tv
export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:${LD_LIBRARY_PATH:-}"
cd xr_teleoperate/teleop

python -u teleop_hand_and_arm.py \
  --input-mode controller \
  --arm G1_29 \
  --ee dex1 \
  --sim \
  --record \
  --img-server-ip 192.168.137.134 \
  --network-interface wlx6c1ff7877849
```

## 8. 你这份仓库已包含的本地修复
- `unitree_sim_isaaclab/dds/dds_master.py`：支持 `UNITREE_DDS_NETWORK_INTERFACE`
- `xr_teleoperate/teleop/teleop_hand_and_arm.py`：修复单目录制 `head_img` 类型
- `xr_teleoperate/teleop/utils/episode_writer.py`：无效帧保护
- `scripts/apply_numba_coverage_hotfix.sh`：numba/coverage 启动兼容补丁
