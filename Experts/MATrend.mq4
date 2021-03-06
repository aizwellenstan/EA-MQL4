//+------------------------------------------------------------------+
//|                                                      MATrend.mq4 |
//|                                       Copyright 448036253@qq.com |
//|                                              http://www.mql4.com |
/* 趋势跟踪   */
//+------------------------------------------------------------------+
#property copyright "Copyright 2018 "
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//EA唯一性标记
#define MAGICMA  201909101

//--- 输入参数
input double Lots            =0.01;        //每单(手数)的交易量

//--- 程序变量
// 开发模式
bool debug = false;


//+------------------------------------------------------------------+
/* 初始化 */
//+------------------------------------------------------------------+
int OnInit()
{
   Print("EA初始化了……");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
/* 运行结束 */
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{ 
   Print("EA运行结束，已经卸载。" );
}

//+------------------------------------------------------------------+
/* 图标Tick事件 */
//+------------------------------------------------------------------+
void OnTick()
{
   // 检测蜡烛图是否足够数量，数量少了不足以形成可靠的周期线
   if(Bars(_Symbol,_Period)<60) // 如果总柱数少于60
   {
      Print("我们只有不到60个报价柱，无法用于计算可靠的指标, EA 将要退出!!");
      return;
   }
   
   // 当前一个报价柱收盘时执行：形成新的K线柱时前一根k柱刚刚收盘，判断方法：当前K线的成交价次数>1时
   if(Volume[0]>1) {
      return;
   }
   
   // 当前周期均线（均线周期选自mt4的一个默认模版的均线组周期13和21）
   // 快速均线（时间周期小）
   double maFst=iMA(_Symbol,PERIOD_CURRENT,13,0,MODE_SMA,PRICE_CLOSE,0);
   // 慢速均线（时间周期大）
   double maSlw=iMA(_Symbol,PERIOD_CURRENT,21,0,MODE_SMA,PRICE_CLOSE,0);
   // 上一个快速均线（时间周期小）
   double maFstPre=iMA(_Symbol,PERIOD_CURRENT,13,0,MODE_SMA,PRICE_CLOSE,1);
   // 上一个慢速均线（时间周期大）
   double maSlwPre=iMA(_Symbol,PERIOD_CURRENT,21,0,MODE_SMA,PRICE_CLOSE,1);
   
   // 大周期使用MACD判断方向（均线对方向比较迟钝） : 当前周期x4，差不多15m对应1h，1h对应4h   
   //MACD主要，大周期
   double macdMain = iMACD(_Symbol,Period()*4,12,26,9,PRICE_CLOSE,MODE_MAIN,1);
   //MACD信号，大周期
   double macdSignal = iMACD(_Symbol,Period()*4,12,26,9,PRICE_CLOSE,MODE_SIGNAL,1);
   
   // 多头：金叉做多，平空单
   if(maFstPre<maSlwPre && maFst>maSlw){
      CheckForClose(-1);
      if(macdSignal>0 || macdMain>macdSignal)CalcForOpen(1);
   }
   // 空头：死叉做空，平多单
   else if(maFstPre>maSlwPre && maFst<maSlw){
      CheckForClose(1);
      if(macdSignal<0 || macdMain<macdSignal)CalcForOpen(-1);
   }
   // 震荡
      
   
}

//+------------------------------------------------------------------+
/* 统计当前图表货币的持仓订单数 */
//+------------------------------------------------------------------+
int OrdersCount()
{
    int count = 0;
   // 遍历订单处理
   for(int i=0;i<OrdersTotal();i++)
   {
      // 选中仓单，选择不成功时，跳过本次循环
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false)
      {
         Print("注意！选中仓单失败！序号=[",i,"]");
         continue;
      }
      //如果 仓单编号不是本系统编号，或者 仓单货币对不是当前货币对时，跳过本次循环
      if(OrderMagicNumber() != MAGICMA || OrderSymbol()!= _Symbol)
      { 
         Print("注意！订单魔术标记不符！仓单魔术编号=[",OrderMagicNumber(),"]","本EA魔术编号=[",MAGICMA,"]");
         continue;
      }
      if(OrderSymbol() == _Symbol)
      {
         count++;
      }      
   }
   return count;
}

//+------------------------------------------------------------------+
/* 计算开仓 */
//+------------------------------------------------------------------+
void CalcForOpen(int type)
{
   
    // TODO资金管理：计算开仓量
   
    // 当前货币持仓情况下不开新仓
    int openCount = OrdersCount();
    if(openCount>0)
    {
        if(debug)Print("当前已持仓：货币[",_Symbol,"]，数量=[",openCount,"]");
        return;
    }
        
    /* 趋势跟踪类，无固定止盈止损 */
    if(type>0)
    {
        //发送仓单（当前货币对，卖出方向，手数，买价，滑点=0，止损0点，止赢0点，备注，EA编号，不过期，标上红色箭头）
        Print("【多】单开仓结果：",OrderSend(_Symbol,OP_BUY,Lots,Ask,0,0,0,"buy",MAGICMA,0,Red));
        return;
    }   
    
    if(type<0)
    {        
        //发送仓单（当前货币对，买入方向，手数，卖价，滑点=0，止损0点，止赢0点，备注，EA编号，不过期，标上蓝色箭头）
        Print("【空】单开仓结果：",OrderSend(_Symbol,OP_SELL,Lots,Bid,0,0,0,"sell",MAGICMA,0,Blue));
        return;
    }
}

//+------------------------------------------------------------------+
//| 平仓，关闭订单
//+------------------------------------------------------------------+
void CheckForClose(int type)
{
   // 遍历订单处理
   for(int i=0;i<OrdersTotal();i++)
   {
      // 选中仓单，选择不成功时，跳过本次循环
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false)
      {
         Print("注意！选中仓单失败！序号=[",i,"]");
         continue;
      }
      //如果 仓单编号不是本系统编号，或者 仓单货币对不是当前货币对时，跳过本次循环
      if(OrderMagicNumber() != MAGICMA || OrderSymbol()!= _Symbol)
      { 
         Print("注意！订单魔术标记不符！仓单魔术编号=[",OrderMagicNumber(),"]","本EA魔术编号=[",MAGICMA,"]");
         continue;
      }
      // 多单平仓：
      if(type>0 && OrderType()==OP_BUY)
      {
         if(!OrderClose(OrderTicket(),OrderLots(),Bid,2,White)) Print("关闭[多]单出错",GetLastError());
      }
      // 空单平仓：
      if(type<0 && OrderType()==OP_SELL)
      {
         if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White)) Print("关闭[空]单出错",GetLastError());
      }
   }
}