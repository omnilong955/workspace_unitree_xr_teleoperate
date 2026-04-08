# XR Teleoperate 环境审查与运行笔记（2026-04-08）

## 1. 审查范围
本笔记覆盖以下内容：
- 本地源码改动记录（含改动文件、目的、关键行）
- 本地环境与关键软件版本
- 证书与网络配置现状
- 可复现的正确启动步骤（Dex3 与 Dex1 两套）
- 常见故障与快速检查

工作目录：`/home/long/workspace_unitree_xr_teleoperate`

---

## 2. 当前系统与网络信息
- OS: `Ubuntu 22.04.5 LTS`
- Kernel: `6.8.0-40-generic`
- Hostname: `robotlab1-ThinkStation-P3-Tower`
- GPU: `NVIDIA GeForce RTX 4090`
- NVIDIA Driver: `580.95.05`
- 当前联调网卡: `wlx6c1ff7877849`
- 当前联调 IPv4: `192.168.137.134/24`

---

## 3. Conda 与环境
- Miniforge 安装位置: `/home/long/workspace_unitree_xr_teleoperate/miniforge3`
- Conda 版本: `26.1.1`

### 3.1 `unitree_sim_env`（仿真环境）
- Python: `3.10.20`
- numpy: `1.26.4`
- numba: `0.65.0`
- coverage: `7.6.1`
- torch: `2.5.1+cu121`
- isaacsim: `4.5.0.0`
- isaacsim-app: `4.5.0.0`
- isaacsim-kernel: `4.5.0.0`
- isaaclab: `0.40.6`
- unitree_sdk2py: `1.0.1`（editable）

### 3.2 `tv`（遥操作环境）
- Python: `3.10.20`
- numpy: `1.26.4`
- pinocchio: `3.1.0`（import OK）
- torch: `2.3.0+cpu`
- meshcat: `0.3.2`
- vuer: `0.0.60`
- televuer: `4.0.0`（editable）
- teleimager: `1.5.0`（editable）
- dex-retargeting: `0.4.7`（editable，import OK）
- websockets: `16.0`
- aiohttp: `3.10.5`
- nlopt: `2.7.1`
- matplotlib: `3.7.5`
- rerun-sdk: `0.20.1`
- sshkeyboard: `2.3.1`
- unitree_sdk2py: `1.0.1`（editable）

---

## 4. 仓库版本与改动状态

### 4.1 仓库提交版本
- `unitree_sim_isaaclab`: `e30c25b`
- `xr_teleoperate`: `02deb60`
- `unitree_sdk2_python`: `ab0d8ae`

### 4.2 源码改动（人工改动）

#### 改动 A：DDS 网卡绑定可配置
- 文件: `/home/long/workspace_unitree_xr_teleoperate/unitree_sim_isaaclab/dds/dds_master.py`
- 关键位置: 第 `5` 行、`61-69` 行
- 变更内容:
  - 新增 `import os`
  - 支持通过环境变量 `UNITREE_DDS_NETWORK_INTERFACE` 指定 DDS 绑定网卡
  - 有值时执行 `ChannelFactoryInitialize(1, networkInterface=...)`
  - 无值时保持原逻辑 `ChannelFactoryInitialize(1)`
- 目的:
  - 在多网卡机器上稳定绑定到实际联调用网卡，减少 `Waiting to subscribe dds...` 问题

#### 改动 B：单目录制帧类型修复
- 文件: `/home/long/workspace_unitree_xr_teleoperate/xr_teleoperate/teleop/teleop_hand_and_arm.py`
- 关键位置: 第 `405-409` 行
- 变更内容:
  - 单目分支下，原先直接写 `head_img`
  - 修改为优先写 `head_img.bgr`，并在异常类型时输出 warning
- 目的:
  - 修复录制时报错：`imwrite ... img is not a numpy array`

#### 改动 C：录制线程增加无效帧保护
- 文件: `/home/long/workspace_unitree_xr_teleoperate/xr_teleoperate/teleop/utils/episode_writer.py`
- 关键位置: 第 `171-175` 行、`183-187` 行
- 变更内容:
  - 对 `colors` 与 `depths` 增加 `None/非 np.ndarray` 检查
  - 非法帧直接跳过并记录 warning，不再触发 `cv2.imwrite` 异常
- 目的:
  - 提高录制稳定性，避免偶发空帧导致线程报错

### 4.3 非仓库热修（site-packages 本地补丁）
- 文件: `/home/long/workspace_unitree_xr_teleoperate/miniforge3/envs/unitree_sim_env/lib/python3.10/site-packages/numba/misc/coverage_support.py`
- 关键位置: 第 `22-25` 行
- 变更内容:
  - 增加 `coverage.types.Tracer` 存在性检查
  - 缺失时禁用 `coverage_available`
- 目的:
  - 规避 Isaac Sim 启动时与 coverage API 版本不匹配导致的崩溃
- 注意:
  - 这是环境内补丁，不在 git 管理中
  - 未来重建 `unitree_sim_env` 后需重新应用

### 4.4 运行生成文件说明
- `unitree_sim_isaaclab` 下出现大量 `__pycache__/*.pyc` 修改，属于运行时缓存，不是业务源码改动。

---

## 5. 证书与 HTTPS/WSS 现状

当前 televuer 证书位置：
- `/home/long/.config/xr_teleoperate/cert.pem`
- `/home/long/.config/xr_teleoperate/key.pem`

当前证书信息：
- `CN=10.204.1.57`
- SAN: `DNS:localhost, IP:10.204.1.57, IP:127.0.0.1`

注意：你当前 IP 已变更为 `192.168.137.134`。若 XR 端因证书信任出现异常，建议重签证书并包含新 IP 的 SAN。

重签示例：
```bash
cd /home/long/workspace_unitree_xr_teleoperate/xr_teleoperate/teleop/televuer
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout key.pem -out cert.pem \
  -subj "/CN=192.168.137.134" \
  -addext "subjectAltName=DNS:localhost,IP:192.168.137.134,IP:127.0.0.1"
mkdir -p ~/.config/xr_teleoperate
cp -f cert.pem key.pem ~/.config/xr_teleoperate/
```

---

## 6. 正确启动步骤（联调）

若新终端提示 `conda: command not found`，先执行：
```bash
source /home/long/workspace_unitree_xr_teleoperate/miniforge3/etc/profile.d/conda.sh
```

## 6.1 Dex3（手势跟踪）

终端 A（仿真）：
```bash
conda activate unitree_sim_env
cd /home/long/workspace_unitree_xr_teleoperate/unitree_sim_isaaclab

# 如需强制网卡（可选）
export UNITREE_DDS_NETWORK_INTERFACE=wlx6c1ff7877849

python -u sim_main.py \
  --device cpu \
  --enable_cameras \
  --task Isaac-PickPlace-Cylinder-G129-Dex3-Joint \
  --enable_dex3_dds \
  --robot_type g129
```

终端 B（遥操）：
```bash
conda activate tv
cd /home/long/workspace_unitree_xr_teleoperate/xr_teleoperate/teleop

python -u teleop_hand_and_arm.py \
  --input-mode hand \
  --arm G1_29 \
  --ee dex3 \
  --sim \
  --record \
  --img-server-ip 192.168.137.134 \
  --network-interface wlx6c1ff7877849
```

XR 端操作：
- 先访问（若 head_camera 开启 webrtc）`https://192.168.137.134:60001` 并信任证书
- 再访问 `https://192.168.137.134:8012/?ws=wss://192.168.137.134:8012`
- 进入页面点击 `Virtual Reality`
- 终端按 `r` 开始同步

重要说明：
- `dex3 + hand` 是手势骨架控制，不是手柄扳机控制。

## 6.2 Dex1（手柄扳机）

终端 A（仿真，必须切 Dex1 任务）：
```bash
conda activate unitree_sim_env
cd /home/long/workspace_unitree_xr_teleoperate/unitree_sim_isaaclab

export UNITREE_DDS_NETWORK_INTERFACE=wlx6c1ff7877849

python -u sim_main.py \
  --device cpu \
  --enable_cameras \
  --task Isaac-PickPlace-Cylinder-G129-Dex1-Joint \
  --enable_dex1_dds \
  --robot_type g129
```

终端 B（遥操）：
```bash
conda activate tv
cd /home/long/workspace_unitree_xr_teleoperate/xr_teleoperate/teleop

python -u teleop_hand_and_arm.py \
  --input-mode controller \
  --arm G1_29 \
  --ee dex1 \
  --sim \
  --record \
  --img-server-ip 192.168.137.134 \
  --network-interface wlx6c1ff7877849
```

重要说明：
- `dex1 + controller` 才是手柄扳机控制开合。
- `dex3` 与 `dex1` 的仿真 task / DDS 开关不能混用。

---

## 7. 验收与快速诊断

常用验收日志：
- 仿真侧出现 `controller started, start main loop...`（GUI 模式下需点一下窗口激活）
- 遥操侧出现 `Subscribe dds ok.`（arm/hand）
- Web 端能打开 `8012` 页面且不显示离线

常用检查命令：
```bash
# 端口监听
ss -lntp | rg '(:8012|:60000|:60001)'

# 本机网络
ip -4 addr show wlx6c1ff7877849

# GPU 驱动
nvidia-smi
```

PICO 显示离线常见原因：
- URL 缺少 `?ws=wss://...`
- 自签名证书未在设备端完成信任
- Wi-Fi 侧 AP/客户端隔离

---

## 8. 备注
- 本次记录时，`ufw` 状态为不活动（`inactive`）。
- 如未来更换网络 IP，请同步更新：
  - `--img-server-ip`
  - XR 浏览器访问地址
  - 证书 SAN（建议）
