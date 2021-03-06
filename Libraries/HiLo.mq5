//+------------------------------------------------------------------+
//|                                                         HiLo.mq5 |
//|                                                   Rodrigo Morais |
//|                                                                  |
//+------------------------------------------------------------------+
#property library
#property copyright "Rodrigo Morais"
#property link      ""
#property version   "1.00"

enum MEASUREMENT{
  STANDARD, // Standard
  BODY      // Body
};

void getAveragePrice(double& sell,
                     double& buy,
                     const int periods,
                     const double &high[],
                     const double &low[],
                     const double &open[],
                     const double &close[],
                     const MEASUREMENT measurement,
                     const int current)
{

    if(measurement == STANDARD) {
      for(int j = 0; j < periods; j++)
      {
         sell = sell + high[(current -1) - j] / periods;
         buy = buy + low[(current -1) - j] / periods;
      }
    } else {
      for(int j = 0; j < periods; j++)
      {
        if(open[(current -1) - j] >= close[(current -1) - j]) {
          sell = sell + open[(current -1) - j] / periods;
          buy = buy + close[(current -1) - j] / periods;
        } else {
          sell = sell + close[(current -1) - j] / periods;
          buy = buy + open[(current -1) - j] / periods;
        }
      }
    }
}

bool isUndefinedPosition(const double sell,
                       const double buy,
                       const double close)
{
  return(close >= buy && close <= sell);
} 

bool isToBuy(const double buy,
             const double sell,
             const double close,
             const bool isPrevLo)
{
  if (isPrevLo) {
    if (close >= buy) { return true; }
    else { return false; }
  } else {
    if (close <= sell) { return false; }
    else { return true; }
  }
}

bool isNewBar() {
  static datetime lastTime = 0;
  datetime lastBarTime = SeriesInfoInteger(Symbol(), Period(), SERIES_LASTBAR_DATE);

  if(lastTime == 0) {
    lastTime = lastBarTime;
    return false;
  }

  if(lastTime != lastBarTime) {
    lastTime = lastBarTime;
    return true;
  }

  return false;
}

void drawCandle(double sell,
                double  buy,
                double  close,
                bool    &isPrevLo,
                double& Superior,
                double& Inferior)
{
  if (isUndefinedPosition(sell, buy,  close)) {
    if (isPrevLo) {
      Inferior = buy;
    } else {
      Superior = sell;
    }
  }
  else {
    if (isToBuy(buy, sell, close, isPrevLo)) {
      Inferior = buy;
    } else {
      Superior = sell;
   }
  }
}

void draw(const int rates_total,
       const int prev_calculated,
       bool& isPrevLo,
       const double &open[],
       const double &high[],
       const double &low[],
       const double &close[],
       const MEASUREMENT measurement,
       const int periods,
       double& Superior[],
       double& Inferior[],
       char& Comments[])
{
  if (prev_calculated == 0) {
    for(int i=periods; i < rates_total; i++) {
      double sell = 0;
      double buy = 0;

      getAveragePrice(sell, buy, periods, high, low, open, close, measurement, i);

      Inferior[i] = 0;
      Superior[i] = 0;
      drawCandle(sell, buy, close[i], isPrevLo, Superior[i], Inferior[i]);

      isPrevLo = Inferior[i] > 0;
    }
    isPrevLo = Inferior[rates_total - 1] > 0;
  } else {
      double  sell    = 0;
      double  buy     = 0;
      int     current = rates_total - 1;

      if (isNewBar()) {
        isPrevLo = Inferior[current - 1] > 0;
      }

      getAveragePrice(sell, buy, periods, high, low, open, close, measurement, current);

      
      StringToCharArray("\nCurrent: " + current + " - Price: " + close[current] +
          "\nisPrevLo: " + isPrevLo +
          "\nSell: " + NormalizeDouble(sell, 0) + " - Buy: " + NormalizeDouble(buy, 0) +
          "\nCandle 1 - High: " + high[(current - 3)] + " - Low: " + low[(current - 3)] + " - Open: " + open[current - 3] + " - Close: " + close[current - 3] +
          "\nCandle 2 - High: " + high[(current - 2)] + " - Low: " + low[(current - 2)] + " - Open: " + open[current - 2] + " - Close: " + close[current - 2] +
          "\nCandle 3 - High: " + high[(current - 1)] + " - Low: " + low[(current - 1)] + " - Open: " + open[current - 1] + " - Close: " + close[current - 1] +
          "\nShould: " + ((close[current] > buy && close[current] > sell) || (isPrevLo && close[current] >= buy) ? "BUY" : "SELL"), Comments);

      Inferior[current] = 0;
      Superior[current] = 0;

      drawCandle(sell, buy, close[current], isPrevLo, Superior[current], Inferior[current]);
  }
}
