//-----------------------------------------------------------------------------
// File name : ddr3_sdram_model_wrapper.sv
// Description : Micron DDR3 仿真模型配置包装
//   等效颗粒 MT41J256M8-093（2Gb / x8 位宽 / 15bit 行地址）
//   宏定义方式与 Vivado 自带模板 ddr3_sdram_model_wrapper.sv 一致
//   注：sg093 速率档 TCK 范围 938~3300ps，覆盖本设计 3125ps 内存时钟；
//       不定义 MAX_MEM（模型内存驻留仿真器，CQE 测试地址空间很小）
//-----------------------------------------------------------------------------
`define den2048Mb
`define sg093
`define x8
//`define MAX_MEM
`include "ddr3.v"
