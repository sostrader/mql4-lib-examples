//+------------------------------------------------------------------+
//| Module: Experts/TimeFrameChart.mq4                               |
//| This file is part of the mql4-lib-examples project:              |
//|     https://github.com/dingmaotu/mql4-lib-examples               |
//|                                                                  |
//| Copyright 2015-2017 Li Ding <dingmaotu@hotmail.com>              |
//|                                                                  |
//| Licensed under the Apache License, Version 2.0 (the "License");  |
//| you may not use this file except in compliance with the License. |
//| You may obtain a copy of the License at                          |
//|                                                                  |
//|     http://www.apache.org/licenses/LICENSE-2.0                   |
//|                                                                  |
//| Unless required by applicable law or agreed to in writing,       |
//| software distributed under the License is distributed on an      |
//| "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,     |
//| either express or implied.                                       |
//| See the License for the specific language governing permissions  |
//| and limitations under the License.                               |
//+------------------------------------------------------------------+
#property copyright "Copyright (C) 2015-2017, Li Ding"
#property link      "dingmaotu@hotmail.com"
#property description "Non standard time frame chart implementation"
#property description "Run this on a standard time frame (smaller than the target period)"
#property description "Make sure the target period is a multiple of the standard time frame."
#property description "e.g. if you want M3 then use M1; if you want M35 then use M5"
#property strict

#include <Mql/UI/Chart.mqh>
#include <Mql/History/TimeSeriesData.mqh>
#include <Mql/Lang/ExpertAdvisor.mqh>
#include <Mql/Charts/TimeFrameChart.mqh>
//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
class TimeFrameChartEAParam: public AppParam
  {
   ObjectAttr(int,targetPeriod,TargetPeriod);
   ObjectAttr(bool,autoOpen,AutoOpen);
public:
   bool              check()
     {
      if(m_targetPeriod<1)
        {
         Alert("Error: Parameter <Target Time Frame> must be positive.");
         return false;
        }
      if(m_targetPeriod<=_Period)
        {
         Alert("Error: Parameter <Target Time Frame> must be larger than current standard time frame.");
         return false;
        }
      if(m_targetPeriod%_Period!=0)
        {
         Alert("Error: Parameter <Target Time Frame> must be a multiple of current standard time frame.");
         return false;
        }
      if(IsStandardTimeframe(m_targetPeriod))
        {
         Alert("Error: Parameter <Target Time Frame> must not be one of the standard timeframes.");
         return false;
        }
      return true;
     }
  };
//+------------------------------------------------------------------+
//| Main EA                                                          |
//+------------------------------------------------------------------+
class TimeFrameChartEA: public ExpertAdvisor
  {
private:
   TimeFrameChart    m_chart;
   TimeSeriesData    m_data;
   int               m_targetPeriod;
   MqlRates          m_lastestRates[];
protected:
   long              findTargetChartId() const
     {
      foreachchart(c)
        {
         if(c.isOffline() && c.getSymbol()==m_data.getSymbol() && c.getPeriod()==m_targetPeriod)
            return c.getId();
        }
      return 0;
     }
   void              forcePriceUpdate()
     {
      //--- as WindowHandle method has been removed in MT5,
      //--- for better compatibility we iterate through charts to find the target chart.
      foreachchart(c)
        {
         if(c.isOffline() && c.getSymbol()==m_data.getSymbol() && c.getPeriod()==m_targetPeriod)
            c.forcePriceUpdate();
        }
     }
public:
                     TimeFrameChartEA(TimeFrameChartEAParam *param);
   void              main();
  };
//+------------------------------------------------------------------+
//| Run the main method once to force update on initialization       |
//+------------------------------------------------------------------+
TimeFrameChartEA::TimeFrameChartEA(TimeFrameChartEAParam *param)
   :m_chart(_Symbol,param.getTargetPeriod()),
     m_data(_Symbol,PERIOD_CURRENT),
     m_targetPeriod(param.getTargetPeriod())
  {
   main();
   if(param.getAutoOpen() && findTargetChartId()==0)
     {
      ChartOpen(m_data.getSymbol(),m_targetPeriod);
     }
  }
//+------------------------------------------------------------------+
//| On the tick event, we check if new bars generate. If new bars    |
//| generate, we feed the rates to the TimeFrameChart implemention.  |
//| We force update for every tick.                                  |
//+------------------------------------------------------------------+
void TimeFrameChartEA::main()
  {
   m_data.updateCurrent();
   if(m_data.isNewBar())
     {
      int bars=(int)m_data.getNewBars();
      ArrayResize(m_lastestRates,bars,5);
      m_data.copyRates(1,bars,m_lastestRates);
      m_chart.updateByRates(m_lastestRates);
     }
   else
     {
      MqlRates rate[1];
      m_data.copyRates(0,1,rate);
      m_chart.update(rate[0]);
     }
   forcePriceUpdate();
  }

BEGIN_INPUT(TimeFrameChartEAParam)
   INPUT(int,TargetPeriod,3);    // Target Time Frame in minutes (for offline chart)
   INPUT(bool,AutoOpen,true);    // Open the offline chart automatically
END_INPUT

DECLARE_EA(TimeFrameChartEA,true);
//+------------------------------------------------------------------+
