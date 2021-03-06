#property version   "1.01"
#property strict
#property indicator_chart_window
#property indicator_buffers 6


double HighBuffer[];
double LowBuffer[];
double OpenUpperBuffer[];
double CloseUpperBuffer[];
double OpenLowerBuffer[];
double CloseLowerBuffer[];


int    Mult;


int OnInit()
{
   SetIndexBuffer(0, HighBuffer);
   SetIndexStyle(0, DRAW_HISTOGRAM, 0, 1, clrRed);
   SetIndexBuffer(1, LowBuffer);
   SetIndexStyle(1, DRAW_HISTOGRAM, 0, 1, clrWhite);
   SetIndexBuffer(2, OpenUpperBuffer);
   SetIndexStyle(2, DRAW_HISTOGRAM, 0, 3, clrRed);
   SetIndexBuffer(3, CloseUpperBuffer);
   SetIndexStyle(3, DRAW_HISTOGRAM, 0, 3, clrRed);
   SetIndexBuffer(4, OpenLowerBuffer);
   SetIndexStyle(4, DRAW_HISTOGRAM, 0, 3, clrWhite);
   SetIndexBuffer(5, CloseLowerBuffer);
   SetIndexStyle(5, DRAW_HISTOGRAM, 0, 3, clrWhite);
   
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

   int limit = Bars - IndicatorCounted() - 1;
   int min_bars = 21;

   for (int i = limit; i >= 0; i--) {
      if (i > Bars - min_bars) {
         continue;
      }
      
      ma  = iMA(_Symbol, 0, 21, 0, MODE_SMA, PRICE_CLOSE, i);
      
      OpenUpperBuffer[i]  = NULL;
      CloseUpperBuffer[i] = NULL;
      OpenLowerBuffer[i]  = NULL;
      CloseLowerBuffer[i] = NULL;
      
      if (close[i] > ma) {
         HighBuffer[i]  = high[i];
         LowBuffer[i]   = low[i];
         OpenUpperBuffer[i]  = MathMin(open[i], close[i]);
         CloseUpperBuffer[i] = MathMax(open[i], close[i]);
         
         
      } else {
         HighBuffer[i]  = low[i];
         LowBuffer[i]   = high[i];
         OpenLowerBuffer[i]  = MathMax(open[i], close[i]);
         CloseLowerBuffer[i] = MathMin(open[i], close[i]);
      }
   }

   return(rates_total);
}


void OnDeinit(const int reason)
{

}
