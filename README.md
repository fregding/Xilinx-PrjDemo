# DemoStd FPGA 学习工程 README

> 文件编码：GB2312  
> 工程类型：Xilinx Vivado + SystemVerilog 学习验证工程  
> 说明：本工程用于整理基础 RTL、存储与时钟管理、低速外设、AXI4/native DDR3 读写等实验，配套《FPGA开发纪要》使用。

## 1. 项目简介

DemoStd 是一个基于 Vivado 的 FPGA 学习实践工程，内容覆盖：

- 基础组合逻辑与时序逻辑
- 异步 FIFO、同步 FIFO、双口 RAM
- PLL / MMCM 时钟资源
- UART、SPI、I2C 低速接口
- MIG DDR3 控制器
- AXI4 接口与 native UI 接口 DDR 读写 demo

目标是通过 RTL 编写、Testbench 仿真、波形对比和 DDR 读写校验，完成从基础模块到 DDR3 控制器接口的入门实践。

## 2. 开发环境

- 开发工具：Xilinx Vivado
- 工程文件：DemoStd.xpr
- 设计语言：SystemVerilog / Verilog
- 约束文件：XDC
- 仿真工具：Vivado Simulator / XSim
- 目标器件与 Vivado 版本：以 DemoStd.xpr 实际配置为准
- 文件编码：GB2312

## 3. 代码结构与项目总结

```text
DemoStd/
├─ DemoStd.xpr                         Vivado 工程配置与文件集
├─ DemoStd.srcs/
│  ├─ sources_1/
│  │  ├─ *.sv                          基础 RTL、异步 FIFO
│  │  ├─ LowSpeedPeripheral/           UART、SPI、I2C
│  │  ├─ DDR3demo/                     Native UI、AXI4 demo
│  │  └─ ip/                           RAM、FIFO、时钟及 DDR3 IP
│  └─ sim_1/
│     ├─ tb_*.sv                       基础模块与 IP 的测试平台
│     ├─ LowSpeedPeripheral/           外设测试平台
│     └─ DDR3demo/                     DDR3 测试平台和波形配置
├─ DemoStd.sim/                        XSim 日志、波形等运行产物
├─ DemoStd.runs/                       综合、实现与 IP 运行产物
├─ DemoStd.cache/                      Vivado 缓存
└─ DemoStd.ip_user_files/              IP 生成的仿真辅助文件