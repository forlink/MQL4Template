//+------------------------------------------------------------------+
//|                                            TemplateIndicator.mqh |
//|                                 Copyright 2018, Keisuke Iwabuchi |
//|                                        https://order-button.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Keisuke Iwabuchi"
#property link      "https://order-button.com/"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 4


#include <Template_1.01.mqh>


double HighBuffer[];
double LowBuffer[];
double OpenBuffer[];
double CloseBuffer[];


int    Mult;


int OnInit()
{
   SetIndexBuffer(0, HighBuffer);
   SetIndexStyle(0, DRAW_HISTOGRAM, 0, 1, clrRed);
   SetIndexBuffer(1, LowBuffer);
   SetIndexStyle(1, DRAW_HISTOGRAM, 0, 1, clrWhite);
   SetIndexBuffer(2, OpenBuffer);
   SetIndexStyle(2, DRAW_HISTOGRAM, 0, 3, clrWhite);
   SetIndexBuffer(3, CloseBuffer);
   SetIndexStyle(3, DRAW_HISTOGRAM, 0, 3, clrRed);
   
   Mult = (Digits == 3 || Digits == 5) ? 10 : 1;
   
   return(INIT_SUCCEEDED);
}


int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   double ma;

   int limit = Bars - IndicatorCounted();
   int min_bars = 21;

   for(int i = limit; i >= 0; i--){
      if(i > Bars - min_bars) {
         continue;
      }
      
      ma  = iMA(_Symbol, 0, 21, 0, MODE_SMA, PRICE_CLOSE, i);
      
      if (close[i] > ma) {
         HighBuffer[i]  = high[i];
         LowBuffer[i]   = low[i];
         OpenBuffer[i]  = MathMin(open[i], close[i]);
         CloseBuffer[i] = MathMax(open[i], close[i]);
      } else {
         HighBuffer[i]  = low[i];
         LowBuffer[i]   = high[i];
         
         CloseBuffer[i] = MathMin(open[i], close[i]);
         OpenBuffer[i]  = MathMax(open[i], close[i]);
      }
   }

   return(rates_total);
}


void OnDeinit(const int reason)
{

}
