//+------------------------------------------------------------------+
//|                                                     Template.mqh |
//|                                 Copyright 2018, Keisuke Iwabuchi |
//|                                        https://order-button.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Keisuke Iwabuchi"
#property link      "https://order-button.com/"
#property strict
#property version   "1.00"


#define COMMENT "EA"
#define OPEN_POS 6
#define ALL_POS  7
#define PEND_POS 8


/**
 * MT4標準時間足
 */
enum timeframes
{
   CURRENT = 0,      // Current timeframe
   M1      = 1,      // 1 minute
   M5      = 5,      // 5 minutes
   M15     = 15,     // 15 minutes
   M30     = 30,     // 30 minutes
   H1      = 60,     // 1 hour
   H4      = 240,    // 4 hours
   D1      = 1440,   // 1 day
   W1      = 10080,  // 1 week
   MN1     = 43200   // 1 month
};


/**
 * true, falseの代わり
 */
enum status
{
   ON = 1,
   OFF = 0
};


/**
 * 取引方向
 */
enum trade
{
   BUY = 1,
   SELL = -1,
   NO_TRADE = 0
};


// 外部変数
int    TradeBar;
int    Mult;
bool   IsTrade;
int    ObjectCount;


/**
 * 外部変数の初期化を実行する
 */
void ProgramInitialize()
{
   // 外部変数の初期化
   TradeBar = Bars;
   Mult = (_Digits == 3 || _Digits == 5) ? 10 : 1;
   // EZインベスト証券 USDJPY 4桁対応
   if  (AccountCompany() == "EZ Invest Securities Co., Ltd." &&
      StringSubstr(_Symbol, 0, 6) == "USDJPY") {
      Mult = 100;
   }
   IsTrade = true;
   ObjectCount = 0;
}


/**
 * EA用の初期化処理を実行する
 *
 * @dependencies ProgramInitialize
 */
void ExpertInitialize()
{
   ProgramInitialize();

   // 口座のチェックアップ
   //--- ターミナルの自動売買の許可を確認
   if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) {
      Alert("MT4のオプションを開き、"
         + "「自動売買を許可する」がチェックされているか確認して下さい。");
   } else if (!MQLInfoInteger(MQL_TRADE_ALLOWED)) {
      Alert("エキスパートアドバイザーの設定を開き、"
      + "全般タブにて「自動売買を許可する」にチェックを入れて下さい。"
      + __FILE__);
   }
   
   //--- 口座の自動売買の許可を確認
   if (!AccountInfoInteger(ACCOUNT_TRADE_EXPERT)) {
      Alert("このアカウントは自動売買が許可されていません。"
         + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)));
   }
   if (!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)) {
      Alert("このアカウントは自動売買が許可されていません。"
         + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)));
   }
   
   // インジケーターを非表示
   HideTestIndicators(true);
}


/**
 * 終了処理を実行する
 * コメントの消去, オブジェクトの削除を行う
 * ただしビジュアルモードでのバックテスト時には検証のため削除を行わない
 */
void ProgramDeinit()
{
   if (IsVisualMode()) {
      Comment("");
      
      for (int i = 0; i < ObjectCount; i++) {
         ObjectDelete(0, "Obj" + IntegerToString(i));
      }
   }
}


/**
 * 保有中ポジションの取引数量を取得する
 *
 * @param type  検索タイプ
 * @param magic  マジックナンバー
 *
 * @return  該当ポジションの合計取引数量
 */
double getOrderLots(int type, int magic)
{
   double lots = 0.0;

   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS)) {
         break;
      }
      if (OrderSymbol() != _Symbol || OrderMagicNumber() != magic) {
         continue;
      }
      
      switch (type) {
         case OP_BUY:
            if (OrderType() == OP_BUY) {
               lots += OrderLots();
            }
            break;
         case OP_SELL:
            if (OrderType() == OP_SELL) {
               lots += OrderLots();
            }
            break;
         case OP_BUYLIMIT:
            if (OrderType() == OP_BUYLIMIT) {
               lots += OrderLots();
            }
            break;
         case OP_SELLLIMIT:
            if (OrderType() == OP_SELLLIMIT) {
               lots += OrderLots();
            }
            break;
         case OP_BUYSTOP:
            if (OrderType() == OP_BUYSTOP) {
               lots += OrderLots();
            }
            break;
         case OP_SELLSTOP:
            if (OrderType() == OP_SELLSTOP) {
               lots += OrderLots();
            }
            break;
         case OPEN_POS:
            if (OrderType() == OP_BUY || OrderType() == OP_SELL) {
               lots += OrderLots();
            }
            break;
         case ALL_POS:
            lots += OrderLots();
            break;
         case PEND_POS:
            if (OrderType() == OP_BUYLIMIT || 
                OrderType() == OP_SELLLIMIT || 
                OrderType() == OP_BUYSTOP || 
                OrderType() == OP_SELLSTOP) {
               lots += OrderLots();
            }
            break;
         default:
            break;
      }
   }
   return(lots);
}


/**
 * 保有中ポジションの件数を取得する
 *
 * @param type  検索タイプ
 * @param magic  マジックナンバー
 *
 * @return  該当ポジションのポジション数
 */
int getOrderCount(int type, int magic)
{
   int count = 0;

   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS)) {
         break;
      }
      if (OrderSymbol() != _Symbol || OrderMagicNumber() != magic) {
         continue;
      }
      
      switch (type) {
         case OP_BUY:
            if (OrderType() == OP_BUY) {
               count++;
            }
            break;
         case OP_SELL:
            if (OrderType() == OP_SELL) {
               count++;
            }
            break;
         case OP_BUYLIMIT:
            if (OrderType() == OP_BUYLIMIT) {
               count++;
            }
            break;
         case OP_SELLLIMIT:
            if (OrderType() == OP_SELLLIMIT) {
               count++;
            }
            break;
         case OP_BUYSTOP:
            if (OrderType() == OP_BUYSTOP) {
               count++;
            }
            break;
         case OP_SELLSTOP:
            if (OrderType() == OP_SELLSTOP) {
               count++;
            }
            break;
         case OPEN_POS:
            if (OrderType() == OP_BUY || OrderType() == OP_SELL) {
               count++;
            }
            break;
         case ALL_POS:
            count++;
            break;
         case PEND_POS:
            if (OrderType() == OP_BUYLIMIT || 
                OrderType() == OP_SELLLIMIT || 
                OrderType() == OP_BUYSTOP || 
                OrderType() == OP_SELLSTOP) {
               count++;
            }
            break;
         default:
            break;
      }
   }
   return(count);
}


/**
 * 発注処理を実行する
 *
 * @param type  取引種別
 * @param lots  取引数量
 * @param price  注文価格
 * @param slip  スリッページ
 * @param sl  損切り価格
 * @param tp  利食い価格
 * @param comment  コメント
 * @param magic  マジックナンバー
 *
 * @return  エラーコード, 0は正常終了
 *
 * @dependencies NormalizeLots, ErrorDescription, TradeTypeToString
 */
int Entry(
   const int type,
   double lots,
   double price,
   int slip,
   double sl,
   double tp,
   const string comment,
   const int magic)
{
   if (!IsTradeAllowed()) {
      return(7002);
   }

   int err = -1;
   color arrow = (type % 2 == 0) ? clrBlue : clrRed;
   
   lots = NormalizeLots(lots);
   price = NormalizeDouble(price, Digits);
   sl = NormalizeDouble(sl, Digits);
   tp = NormalizeDouble(tp, Digits);
 
   uint starttime = GetTickCount();
   while(true) {
      if (GetTickCount() - starttime > 5 * 1000) {
         Print("OrderSend timeout.");
         return(7001);
      }
      
      ResetLastError();
      RefreshRates();
      int ticket = OrderSend(
         _Symbol,
         type,
         lots,
         price,
         slip,
         sl,
         tp,
         comment,
         magic,
         0,
         arrow);
      
      if (ticket != -1) {
         return(0);
      }
      
      err = _LastError;
      Print("[OrderSendError] : ", err, " ", ErrorDescription(err));

      if (err == 129) {
         break;
      }
      if (err == 130) {
         Print("bid=", Bid, "type=", TradeTypeToString(type), " price=", price,
               " sl=", sl, " tp=", tp,
               " stoplevel=", MarketInfo(_Symbol, MODE_STOPLEVEL));
         break;
      }
      
      Sleep(100);
   }
   return(err);
}


/**
 * 取引数量を発注可能なロット数に合わせる
 *
 * @param lots  発注予定の取引数量
 * @param symbol  発注する通貨ペア名
 *                省略した場合は現在のチャートの通貨ペア
 *
 * @return  正規化された取引数量
 */
double NormalizeLots(double lots, string symbol = "")
{
   if (symbol == "") {
      symbol = _Symbol;
   }
   
   double max = MarketInfo(symbol, MODE_MAXLOT);
   double min = MarketInfo(symbol, MODE_MINLOT);
   
   if (lots > max) {
      return(max);
   }
   if (lots < min) {
      return(min);
   }
   return(NormalizeDouble(lots, 2));
}


/**
 * 取引種別を文字列として返す
 *
 * @param type  取引種別
 *
 * @return  取引種別の文字列
 */
string TradeTypeToString(const int type)
{
   switch (type) {
      case OP_BUY:
         return("OP_BUY");
      case OP_SELL:
         return("OP_SELL");
      case OP_BUYLIMIT:
         return("OP_BUYLIMIT");
      case OP_SELLLIMIT:
         return("OP_SELLLIMIT");
      case OP_BUYSTOP:
         return("OP_BUYSTOP");
      case OP_SELLSTOP:
         return("OP_SELLSTOP");
      default:
         return("Invalid value");
   }
}


/**
 * 発注処理を実行する
 * slippage, TP/SLはpips単位で指定可能
 *
 * @param type  取引種別
 * @param lots  取引数量
 * @param price  注文価格
 * @param slip  スリッページpips
 * @param sl  損切りpips
 * @param tp  利食いpips
 * @param comment  コメント
 * @param magic  マジックナンバー
 *
 * @return  エラーコード, 0は正常終了
 *
 * @dependencies PipsToPoint, PipsToPrice, Entry
 */
int EntryWithPips(
   const int    type,
   const double lots,
   const double price,
   const double slip,
   const double slpips,
   const double tppips,
   const string comment,
   const int    magic)
{
   int slippage = PipsToPoint(slip);
   double sl = 0;
   double tp = 0;

   if (type == OP_SELL || type == OP_SELLLIMIT || type == OP_SELLSTOP) {
      if (slpips > 0) {
         sl = price + PipsToPrice(slpips);
      }
      if(tppips > 0) {
         tp = price - PipsToPrice(tppips);
      }
   } else {
      if (slpips > 0) {
         sl = price - PipsToPrice(slpips);
      }
      if(tppips > 0) {
         tp = price + PipsToPrice(tppips);
      }
   }
   
   return(Entry(type, lots, price, slippage, sl, tp, comment, magic));
}


/**
 * pips単位の値を価格単位へ変換する
 *
 * @param pips_value  pips単位の値
 *
 * @return  価格単位の値
 */
double PipsToPrice(const double pips_value)
{
   return(pips_value * _Point * Mult);
}


/**
 * pips単位の値をpoint単位へ変換する
 *
 * @param pips_value  pips単位の値
 *
 * @return  point単位の値
 */
int PipsToPoint(const double pips_value)
{
   return((int)(pips_value * Mult));
}


/**
 * magicに一致するオープンポジションを決済する
 * 複数存在する場合は全て決済する
 *
 * @param slippage  スリッページpips
 * @param magic  マジックナンバー
 *
 * @return  true: 決済成功, false: 失敗
 *
 * @dependencies PipsToPoint, ErrorDescription
 */
bool Exit(double slippage, const int magic)
{
   color arrow = clrNONE;
   int type;
   int slip = PipsToPoint(slippage);
   
   for (int i = 0; i < OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS) == false) {
         return(false);
      }
      if (OrderSymbol() != Symbol() || OrderMagicNumber() != magic) {
         continue;
      }
      type = OrderType();
      if (type != OP_BUY && type != OP_SELL) {
         continue;
      }
      if (!IsTradeAllowed()) {
         continue;
      }
      
      arrow = (type % 2 == 0) ? clrBlue : clrRed;
      RefreshRates();
      bool result = OrderClose(
         OrderTicket(),
         OrderLots(),
         OrderClosePrice(),
         slip,
         arrow);
      
      if (!result) {
         return(false);
      }
      
      int err = GetLastError();
      Print("[OrderCloseError] : ", err, " ", ErrorDescription(err));
      if (err == 129) {
         break;
      }
      Sleep(100);
   }

   return(true);
}


/**
 * オープンポジションを変更する
 *
 * @param sl  損切り価格, 0を指定すると現在の価格のまま変更しない
 * @param tp  利食い価格, 0を指定すると現在の価格のまま変更しない
 * @param magic  注文変更ポジションのマジックナンバー
 *
 * @return  true: 成功, false: 失敗
 *
 * @dependencies ErrorDescription
 */
bool Modify(double sl, double tp, const int magic)
{
   int ticket = 0;
   for (int i = 0; i < OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS) == false) {
         break;
      }
      if (OrderSymbol() != Symbol() || OrderMagicNumber() != magic) {
         continue;
      }
      int type = OrderType();
      if (type == OP_BUY || type == OP_SELL) {
         ticket = OrderTicket();
         break;
      }
   }
   if (ticket == 0) {
      return(false);
   }
   
   sl = NormalizeDouble(sl, Digits);
   tp = NormalizeDouble(tp, Digits);

   if (sl == 0) {
      sl = OrderStopLoss();
   }
   if (tp == 0) {
      tp = OrderTakeProfit();
   }
   if (OrderStopLoss() == sl && OrderTakeProfit() == tp) {
      return(false);
   }
   
   ulong starttime = GetTickCount();
   while (true) {
      if (GetTickCount() - starttime > 5 * 1000) {
         Alert("OrderModify timeout. Check the experts log.");
         return(false);
      }
      if (IsTradeAllowed()) {
         if (OrderModify(ticket, 0, sl, tp, 0)) {
            return(true);
         }
         
         int err = GetLastError();
         Print("[OrderModifyError] : ", err, " ", ErrorDescription(err));
         if (err == 1) {
            break;
         }
         if (err == 130) {
            break;
         }
      }
      Sleep(100);
   }
   return(false);
}


/**
 * magicに一致する待機注文を削除する
 * 複数存在する場合は全て削除する
 *
 * @param magic  マジックナンバー
 *
 * @return  true: 成功, false: 失敗
 */
bool Delete(const int magic)
{
   int type;
   
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS)) {
         break;
      }
      if (OrderSymbol() != _Symbol || OrderMagicNumber() != magic) {
         continue;
      }
      
      type = OrderType();
      if (type == OP_BUYLIMIT || type == OP_SELLLIMIT
         || type == OP_BUYSTOP || type == OP_SELLSTOP) {
         if (!OrderDelete(OrderTicket())) {
            return(false);
         }
      }
   }
   
   return(true);
}


/**
 * lower～upperの値幅内で、baseから上下width pips間隔で指値注文を出す。
 *
 * @param base  基準価格
 * @param lower  発注レンジ下限
 * @param upper  発注レンジ上限
 * @param width  発注間隔pips
 * @param lots  取引数量
 * @param sl  損切りpips
 * @param tp  利食いpips
 * @param magic  マジックナンバー
 *
 * @return  true: 成功, false: 失敗
 *
 * @dependencies PipsToPrice, hasOrderByPrice, EntryWithPips
 */
bool RepeatOrder(
   const double base,
   const double lower,
   const double upper,
   const double width,
   const double lots,
   const double sl,
   const double tp,
   const int    magic)
{
   if (upper < lower || width <= 0) {
      return(false);
   }
   
   double price = base;
   int type;
   string comment = "";
   int code = 0;
   
   while (price > lower) {
      price -= PipsToPrice(width);
   }
   price += PipsToPrice(width);
   
   while (price <= upper) {
      if (price < Ask) {
         type = OP_BUYLIMIT;
         comment = DoubleToString(price, _Digits);
      } else if (price > Bid) {
         type = OP_SELLLIMIT;
         comment = DoubleToString(price * -1, _Digits);
      } else {
         price += PipsToPrice(width);
         continue;
      }
      
      if (hasOrderByPrice(type, price, magic) == false) {
         code = EntryWithPips(type, lots, price, 0, sl, tp, comment, magic);
         if (code != 0) {
            return(false);
         }
      }
      
      price += PipsToPrice(width);
      Sleep(100);
   }
   
   return(true);
}


/**
 * lower～upperの値幅内で、baseから上下width pips間隔で待機注文を出す。
 * 待機注文は指値と逆指値の両方を発注する。
 *
 * @param base  基準価格
 * @param lower  発注レンジ下限
 * @param upper  発注レンジ上限
 * @param width  発注間隔pips
 * @param lots  取引数量
 * @param sl  損切りpips
 * @param tp  利食いpips
 * @param magic  マジックナンバー
 *
 * @return  true: 成功, false: 失敗
 *
 * @dependencies PipsToPrice, hasOrderByPrice, EntryWithPips
 */
bool RepeatOrderHedge(
   const double base,
   const double lower,
   const double upper,
   const double width,
   const double lots,
   const double sl,
   const double tp,
   const int    magic)
{
   if (upper < lower || width <= 0) {
      return(false);
   }
   
   double price = base;
   int type_buy, type_sell;
   string comment_buy, comment_sell;
   
   while (price > lower) {
      price -= PipsToPrice(width);
   }
   price += PipsToPrice(width);
   
   while (price <= upper) {
      if (price < Ask) {
         type_buy = OP_BUYLIMIT;
         type_sell = OP_SELLSTOP;
      } else if (price > Bid) {
         type_buy = OP_BUYSTOP;
         type_sell = OP_SELLLIMIT;
      } else {
         price += PipsToPrice(width);
         continue;
      }
      
      if (!hasOrderByPrice(type_buy, price, magic)) {
         comment_buy = DoubleToString(price, _Digits);
         if (EntryWithPips(type_buy, lots, price, 0, sl, tp, comment_buy, magic) != 0) {
            return(false);
         }
      }
      if (!hasOrderByPrice(type_sell, price, magic)) {
         comment_sell = DoubleToString(price, _Digits);
         if (EntryWithPips(type_sell, lots, price, 0, sl, tp, comment_sell, magic) != 0) {
            return(false);
         }
      }
      
      price += PipsToPrice(width);
      Sleep(100);
   }
   
   return(true);
}


/**
 * 取引種別type, エントリー価格price, マジックナンバーmagic
 * と一致するポジションが存在するか確認する
 *
 * @param type  取引種別
 * @param price  価格
 * @param magic  マジックナンバー
 *
 * @return  true: ポジション有り, false: ポジション無し
 */
bool hasOrderByPrice(const int type, double price, const int magic)
{
   int order_type;
   string price_str;
   double comment_price;
   
   price = NormalizeDouble(price, _Digits);
   if (type > 0) {
      price_str = DoubleToString(price, _Digits);
   }
   if (type < 0) {
      price_str = DoubleToString(price * -1, _Digits);
   }
   
   
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         return(true);
      }
      if (OrderSymbol() != _Symbol) {
         continue;
      }
      if (OrderMagicNumber() != magic) {
         continue;
      }
      
      order_type = OrderType();
      comment_price = StringToDouble(
         StringSubstr(OrderComment(), 0, StringLen(price_str))
      );
      
      if (type > 0) {
         if (order_type == OP_BUY ||
            order_type == OP_BUYLIMIT ||
            order_type == OP_BUYSTOP) {
            if (comment_price == price) {
               return(true);
            }
         }
      }
      if (type < 0) {
         if (order_type == OP_SELL ||
            order_type == OP_SELLLIMIT ||
            order_type == OP_SELLSTOP) {
            if (comment_price == price * -1) {
               return(true);
            }
         }
      }
   }
   
   return(false);
}


/**
 * 取引数量の複利計算
 * 計算が不可能な場合は0を返す
 *
 * @param risk  損切りの損失, 口座残高に対する割合(%)
 * @param sl_pips  損切り(pips)
 *
 * @return  取引数量
 *
 * @dependencies PipsToPoint
 */
double MoneyManagement(const double risk, const double sl_pips)
{
   if (risk <= 0 || sl_pips <= 0) {
      return(0);
   }
   
   double lots = AccountBalance() * (risk / 100);
   double tickvalue = MarketInfo(_Symbol, MODE_TICKVALUE);

   if (tickvalue == 0) {
      return(0);
   }
   
   lots = lots / (tickvalue * PipsToPoint(sl_pips));
   
   return(lots);
}


/**
 * トレーリングストップを実行する
 *
 * @param value  トレーリング幅(pips)
 * @param magic  マジックナンバー
 *
 * @dependencies PipsToPrice, Modify
 */
void TrailingStop(const double value, const int magic)
{
   double new_sl;
   
   for (int i = 0; i < OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) {
         return;
      }
      if (OrderSymbol() != _Symbol || OrderMagicNumber() != magic) {
         continue;
      }
      
      if (OrderType() == OP_BUY) {
         new_sl = Bid - PipsToPrice(value);
         if (new_sl >= OrderOpenPrice() && new_sl > OrderStopLoss()) {
            Modify(new_sl, 0, magic);
            break;
         }
      }
      if (OrderType() == OP_SELL) {
         new_sl = Ask + PipsToPrice(value);
         if (new_sl <= OrderOpenPrice() && 
            (new_sl < OrderStopLoss() || OrderStopLoss() == 0)) {
            Modify(new_sl, 0, magic);
            break;
         }
      }
   }
}


/**
 * 建値決済機能
 * value pipsだけ利益が出たポジションの決済SLをエントリー価格に設定する
 *
 * @param value  利益(pips)
 * @param magic  マジックナンバー
 *
 * @dependencies PipsToPrice, Modify
 */
void BreakEven(const double value, const int magic)
{
   double new_sl;
   
   for (int i = 0; i < OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) {
         return;
      }
      if (OrderSymbol() != _Symbol || OrderMagicNumber() != magic) {
         continue;
      }
      
      if (OrderType() == OP_BUY) {
         new_sl = Bid - PipsToPrice(value);
         if (new_sl >= OrderOpenPrice() && new_sl > OrderStopLoss()) {
            Modify(OrderOpenPrice(), 0, magic);
            break;
         }
      }
      if (OrderType() == OP_SELL) {
         new_sl = Ask + PipsToPrice(value);
         if (new_sl <= OrderOpenPrice() &&
            (new_sl < OrderStopLoss() || OrderStopLoss() == 0)) {
            Modify(OrderOpenPrice(), 0, magic);
            break;
         }
      }
   }
}


/**
 * トレードプールから最新のポジション情報を1件選択する
 *
 * @param magic  マジックナンバー
 *
 * @return  true: 選択成功, false: 失敗
 */
bool getOrder(const int magic)
{
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) {
         break;
      }
      if (OrderSymbol() != _Symbol || OrderMagicNumber() != magic) {
         continue;
      }
      return(true);
   }
   return(false);
}


/**
 * ヒストリープールから最新のポジション情報を1件選択する
 *
 * @param magic  マジックナンバー
 *
 * @return  true: 選択成功, false: 失敗
 */
bool getOrderByHistory(const int magic)
{
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) == false) {
         break;
      }
      if (OrderSymbol() != _Symbol || OrderMagicNumber() != magic) {
         continue;
      }
      return(true);
   }
   return(false);
}


/**
 * magicで指定したポジションのエントリー価格を返す
 *
 * @param magic  マジックナンバー
 *
 * @return  エントリー価格
 *
 * @dependencies getOrder
 */
double getOrderOpenPrice(const int magic)
{
   double value = (getOrder(magic)) ? OrderOpenPrice() : 0;
      
   return(value);
}


/**
 * magicで指定したポジションのエントリー価格をヒストリープールから取得して返す
 *
 * @param magic  マジックナンバー
 *
 * @return  エントリー価格
 *
 * @dependencies getOrderByHistory
 */
double getOrderOpenPriceByHistory(const int magic)
{
   double value = (getOrderByHistory(magic)) ? OrderOpenPrice() : 0;
      
   return(value);
}


/**
 * magicで指定したポジションのエントリー時刻を返す
 *
 * @param magic  マジックナンバー
 *
 * @return  エントリー時刻
 *
 * @dependencies getOrder
 */
datetime getOrderOpenTime(const int magic)
{
   datetime value = (getOrder(magic)) ? OrderOpenTime() : 0;
      
   return(value);
}


/**
 * magicで指定したポジションのエントリー時刻をヒストリープールから取得して返す
 *
 * @param magic  マジックナンバー
 *
 * @return  エントリー時刻
 *
 * @dependencies getOrderByHistory
 */
datetime getOrderOpenTimeByHistory(const int magic)
{
   datetime value = (getOrderByHistory(magic)) ? OrderOpenTime() : 0;
      
   return(value);
}


/**
 * magicで指定したポジションの取引種別を返す
 * 取得できなかった場合は-1を返す
 *
 * @param magic  マジックナンバー
 *
 * @return  取引種別
 *
 * @dependencies getOrder
 */
int getOrderType(const int magic)
{
   int value = (getOrder(magic)) ? OrderType() : -1;
      
   return(value);
}


/**
 * magicで指定したポジションの取引種別をヒストリープールから取得して返す
 * 取得できなかった場合は-1を返す
 *
 * @param magic  マジックナンバー
 *
 * @return  取引種別
 *
 * @dependencies getOrderByHistory
 */
int getOrderTypeByHistory(const int magic)
{
   int value = (getOrderByHistory(magic)) ? OrderType() : -1;
      
   return(value);
}


/**
 * magicで指定したポジションの取引数量を返す
 *
 * @param magic  マジックナンバー
 *
 * @return  取引数量
 *
 * @dependencies getOrder
 */
double getOrderLots(const int magic)
{
   double value = (getOrder(magic)) ? OrderLots() : 0;
      
   return(value);
}


/**
 * magicで指定したポジションの取引数量をヒストリープールから取得して返す
 *
 * @param magic  マジックナンバー
 *
 * @return  取引数量
 *
 * @dependencies getOrderByHistory
 */
double getOrderLotsByHistory(const int magic)
{
   double value = (getOrderByHistory(magic)) ? OrderLots() : 0;
      
   return(value);
}


/**
 * magicで指定したポジションのTPを返す
 *
 * @param magic  マジックナンバー
 *
 * @return  TP
 *
 * @dependencies getOrder
 */
double getOrderTakeProfit(const int magic)
{
   double value = (getOrder(magic)) ? OrderTakeProfit() : 0;
      
   return(value);
}


/**
 * magicで指定したポジションのTPをヒストリープールから取得して返す
 *
 * @param magic  マジックナンバー
 *
 * @return  TP
 *
 * @dependencies getOrderByHistory
 */
double getOrderTakeProfitByHistory(const int magic)
{
   double value = (getOrderByHistory(magic)) ? OrderTakeProfit() : 0;
      
   return(value);
}


/**
 * magicで指定したポジションのSLを返す
 *
 * @param magic  マジックナンバー
 *
 * @return  SL
 *
 * @dependencies getOrder
 */
double getOrderStopLoss(const int magic)
{
   double value = (getOrder(magic)) ? OrderStopLoss() : 0;
      
   return(value);
}


/**
 * magicで指定したポジションのSLをヒストリープールから取得して返す
 *
 * @param magic  マジックナンバー
 *
 * @return  SL
 *
 * @dependencies getOrderByHistory
 */
double getOrderStopLossByHistory(const int magic)
{
   double value = (getOrderByHistory(magic)) ? OrderStopLoss() : 0;
      
   return(value);
}


/**
 * magicで指定したポジションの有効期限を返す
 *
 * @param magic  マジックナンバー
 *
 * @return  有効期限
 *
 * @dependencies getOrder
 */
datetime getOrderExpiration(const int magic)
{
   datetime value = (getOrder(magic)) ? OrderExpiration() : 0;
      
   return(value);
}


/**
 * magicで指定したポジションの有効期限をヒストリープールから取得して返す
 *
 * @param magic  マジックナンバー
 *
 * @return  有効期限
 *
 * @dependencies getOrderByHistory
 */
datetime getOrderExpirationByHistory(const int magic)
{
   datetime value = (getOrderByHistory(magic)) ? OrderExpiration() : 0;
      
   return(value);
}


/**
 * magicで指定したポジションのコメントを返す
 *
 * @param magic  マジックナンバー
 *
 * @return  コメント
 *
 * @dependencies getOrder
 */
string getOrderComment(const int magic)
{
   string value = (getOrder(magic)) ? OrderComment() : "";
      
   return(value);
}


/**
 * magicで指定したポジションのコメントをヒストリープールから取得して返す
 *
 * @param magic  マジックナンバー
 *
 * @return  コメント
 *
 * @dependencies getOrderByHistory
 */
string getOrderCommentByHisotry(const int magic)
{
   string value = (getOrderByHistory(magic)) ? OrderComment() : "";
      
   return(value);
}


/**
 * magicで指定したポジションの損益を返す
 *
 * @param magic  マジックナンバー
 *
 * @return  損益
 *
 * @dependencies getOrder
 */
double getOrderProfit(const int magic)
{
   double value = (getOrder(magic)) ? OrderProfit() : 0;
      
   return(value);
}


/**
 * magicで指定したポジションの損益をヒストリープールから取得して返す
 *
 * @param magic  マジックナンバー
 *
 * @return  損益
 *
 * @dependencies getOrderByHistory
 */
double getOrderProfitByHisotry(const int magic)
{
   double value = (getOrderByHistory(magic)) ? OrderProfit() : 0;
      
   return(value);
}


/**
 * magicで指定したポジションのスワップを返す
 *
 * @param magic  マジックナンバー
 *
 * @return  スワップ
 *
 * @dependencies getOrder
 */
double getOrderSwap(const int magic)
{
   double value = (getOrder(magic)) ? OrderSwap() : 0;
      
   return(value);
}


/**
 * magicで指定したポジションのスワップをヒストリープールから取得して返す
 *
 * @param magic  マジックナンバー
 *
 * @return  スワップ
 *
 * @dependencies getOrderByHistory
 */
double getOrderSwapByHistory(const int magic)
{
   double value = (getOrderByHistory(magic)) ? OrderSwap() : 0;
      
   return(value);
}


/**
 * magicで指定したポジションの手数料を返す
 *
 * @param magic  マジックナンバー
 *
 * @return  手数料
 *
 * @dependencies getOrder
 */
double getOrderCommission(const int magic)
{
   double value = (getOrder(magic)) ? OrderCommission() : 0;
      
   return(value);
}


/**
 * magicで指定したポジションの手数料をヒストリープールから取得して返す
 *
 * @param magic  マジックナンバー
 *
 * @return  手数料
 *
 * @dependencies getOrderByHistory
 */
double getOrderCommissionByHistory(const int magic)
{
   double value = (getOrderByHistory(magic)) ? OrderCommission() : 0;
      
   return(value);
}


/**
 * magicで指定したポジションの決済価格をヒストリープールから取得して返す
 *
 * @param magic  マジックナンバー
 *
 * @return  決済価格
 *
 * @dependencies getOrderByHistory
 */
double getOrderClosePriceByHistory(const int magic)
{
   double value = (getOrderByHistory(magic)) ? OrderClosePrice() : 0;
      
   return(value);
}


/**
 * magicで指定したポジションの決済時刻をヒストリープールから取得して返す
 *
 * @param magic  マジックナンバー
 *
 * @return  決済時刻
 *
 * @dependencies getOrderByHistory
 */
datetime getOrderCloseTimeByHistory(const int magic)
{
   datetime value = (getOrderByHistory(magic)) ? OrderCloseTime() : 0;
      
   return(value);
}


/**
 *  取引可能曜日フィルター
 * 
 * @param arr  曜日ごとのフィルターON/OFFの配列 true:取引する, false:しない
 *
 * @return  true: 取引可能, false: 取引不可能
 */
bool DayOfWeekFilter(bool &arr[])
{
   if (ArraySize(arr) != 7) {
      return(false);
   }

   return(arr[DayOfWeek()]); 
}


/**
 * 指定時刻での決済判定
 * exit_timeからinterval(秒)の間は決済と判定する
 *
 * @param exit_time  決済時刻
 * @param interval  決済時刻からの猶予時間
 *
 * @return  true: 決済
 */
bool ExitByTime(const datetime exit_time, const uint interval = 300)
{
   return(TimeCurrent() >= exit_time && TimeCurrent() <= exit_time + interval);
}


/**
 * string型の時間をdatetime型に直す
 *
 * @param value  時刻の文字列, 例: 1:23
 *
 * @return 今日の日付（サーバー時刻）でdatetime型に変換したvalueの時刻
 */
datetime StringToTimeWithServerDate(const string value)
{
   return(StringToTime((string)Year() + "."
      + (string)Month() + "."
      + (string)Day() + " " + value));
}


/**
 * 取引時間帯を制限する
 *
 * @param start_time  取引時間の開始時刻
 * @param end_time  取引時間の終了時刻
 *
 * @return  true: 取引可能時刻, false: 取引不能時刻
 */
bool TradeTimeZoneFilter(const datetime start_time, const datetime end_time)
{
   if (start_time < end_time) {
      return(TimeCurrent() >= start_time && TimeCurrent() < end_time);
   }
   
   return(TimeCurrent() < end_time || TimeCurrent() >= start_time);
}


/**
 * パーフェクトオーダーに一致しているか判定しいる
 * MAは全てSMA, 終値で計算している
 * periodsは最低でも2以上の大きさの配列であること
 *
 * @param type  OP_BUY: 昇順 , OP_SELL: 降順
 * @param periods[]  パーフェクトオーダーに使用するMAの期間をまとめた配列
 * @param shift  計算位置, 初期値は1
 *
 * @return  true:パーフェクトオーダーに一致 , false: 不一致
 */
bool PerfectOrderFilter(const int type, int &periods[], const int shift = 1)
{
   double ma[];
   int size = ArraySize(periods);
   
   if (size < 2) {
      return(false);
   }
   
   ArrayResize(ma, size);
   ArraySort(periods, WHOLE_ARRAY, 0, MODE_ASCEND);
   
   for (int i = 0; i < size; i++) {
      ma[i] = iMA(_Symbol, 0, periods[i], 0, MODE_SMA, PRICE_CLOSE, shift);
      
      if (i == 0) {
         continue;
      }
      
      if (type == OP_BUY) {
         if (ma[i] <= ma[i - 1]) {
            return(false);
         }
      } else if (type == OP_SELL) {
         if (ma[i] >= ma[i - 1]) {
            return(false);
         }
      } else {
         return(false);
      }
   }
   
   return(true);
}


/**
 * 2種類の値のクロスにより取引する
 * value1がvalue2を超えると買い
 * value1がvalue2を下回ると売り
 *
 * @param value1[2]  値の配列1
 * @param value2[2]  値の配列2
 *
 * @return  0:取引なし, 1:買い, -1:売り
 */
int getCrossSignal(double &value1[2], double &value2[2])
{
   if (value1[0] > value2[0] && value1[1] <= value2[1]) {
      return(1);
   }
   if (value1[0] < value2[0] && value1[1] >= value2[1]) {
      return(-1);
   }
   return(0);
}


/**
 * 短期MAと長期MAのクロスで取引する
 *
 * @param small_period  短期MAの期間
 * @param long_period  長期MAの期間
 * @param shift  計算位置
 *
 * @return  0:取引なし, 1:買い, -1:売り
 *
 * @dependencies getCrossSignal
 */
int getMACrossSignal(
   const int small_period,
   const int long_period,
   const int shift = 1)
{
   double small_ma[2], long_ma[2];
   
   small_ma[0] = iMA(_Symbol, 0, small_period, 0, MODE_SMA, PRICE_CLOSE, shift);
   small_ma[1] = iMA(_Symbol, 0, small_period, 0, MODE_SMA, PRICE_CLOSE, shift + 1);
   long_ma[0]  = iMA(_Symbol, 0, long_period,  0, MODE_SMA, PRICE_CLOSE, shift);
   long_ma[1]  = iMA(_Symbol, 0, long_period,  0, MODE_SMA, PRICE_CLOSE, shift + 1);

   return(getCrossSignal(small_ma, long_ma));
}


/**
 * MACDとMACDのシグナルのクロスで取引する
 *
 * @param fast_ema_period  短期EMAの期間
 * @param slow_ema_period  長期EMAの期間
 * @param signal_period  シグナルの期間
 * @param shift  計算位置
 *
 * @return  0:取引なし, 1:買い, -1:売り
 *
 * @dependencies getCrossSignal
 */
int getMACDSignal(
   const int fast,
   const int slow,
   const int signal_period,
   const int shift = 1)
{
   double macd[2], signal[2];
   
   macd[0]   = iMACD(_Symbol, 0, fast, slow, signal_period, PRICE_CLOSE, MODE_MAIN,   shift);
   macd[1]   = iMACD(_Symbol, 0, fast, slow, signal_period, PRICE_CLOSE, MODE_MAIN,   shift + 1);
   signal[0] = iMACD(_Symbol, 0, fast, slow, signal_period, PRICE_CLOSE, MODE_SIGNAL, shift);
   signal[1] = iMACD(_Symbol, 0, fast, slow, signal_period, PRICE_CLOSE, MODE_SIGNAL, shift + 1);

   return(getCrossSignal(macd, signal));
}


/**
 * 1日のローソク足の本数
 *
 * @return 現在のチャートの時間足が、24時間に何本出現するか
 */
int getBarsInDay()
{
   int period = _Period;
   
   if (period <= 0 || period > 1440) {
      return(0);
   }
   
   return(1440 / period);
}


int TimeToShift(const datetime time)
{
   for (int i = 0; i < Bars; i++) {
      if (Time[i] <= time) {
         return(i);
      }
   }
   return(0);
}


/**
 * 時間足を文字列として返す
 *
 * @param period  時間足, 0は現在の時間足
 *
 * @return  時間足の日本語表示
 */
string PeriodToString(int period)
{
   if (period == 0) {
      period = _Period;
   }
   
   switch (period) {
      case PERIOD_M1:
         return("1分足 (M1)");
      case PERIOD_M5:
         return("5分足 (M5)");
      case PERIOD_M15:
         return("15分足 (M15)");
      case PERIOD_M30:
         return("30分足 (M30)");
      case PERIOD_H1: 
         return("1時間足 (H1)");
      case PERIOD_H4:
         return("4時間足 (H4)");
      case PERIOD_D1:
         return("日足 (D1)");
      case PERIOD_W1:
         return("週足 (W1)");
      case PERIOD_MN1:
         return("月足 (MN1)");
      default:
         return("");
   }
}



/**
 * エラー内容を取得する
 *
 * @param error_code  エラーコード
 *
 * @return  エラー内容を表す文字列
 */
string ErrorDescription(int error_code)
{
   string error_string;

   switch (error_code) {
      case 0:
      case 1:   error_string="no error";                                                  break;
      case 2:   error_string="common error";                                              break;
      case 3:   error_string="invalid trade parameters";                                  break;
      case 4:   error_string="trade server is busy";                                      break;
      case 5:   error_string="old version of the client terminal";                        break;
      case 6:   error_string="no connection with trade server";                           break;
      case 7:   error_string="not enough rights";                                         break;
      case 8:   error_string="too frequent requests";                                     break;
      case 9:   error_string="malfunctional trade operation (never returned error)";      break;
      case 64:  error_string="account disabled";                                          break;
      case 65:  error_string="invalid account";                                           break;
      case 128: error_string="trade timeout";                                             break;
      case 129: error_string="invalid price";                                             break;
      case 130: error_string="invalid stops";                                             break;
      case 131: error_string="invalid trade volume";                                      break;
      case 132: error_string="market is closed";                                          break;
      case 133: error_string="trade is disabled";                                         break;
      case 134: error_string="not enough money";                                          break;
      case 135: error_string="price changed";                                             break;
      case 136: error_string="off quotes";                                                break;
      case 137: error_string="broker is busy (never returned error)";                     break;
      case 138: error_string="requote";                                                   break;
      case 139: error_string="order is locked";                                           break;
      case 140: error_string="long positions only allowed";                               break;
      case 141: error_string="too many requests";                                         break;
      case 145: error_string="modification denied because order too close to market";     break;
      case 146: error_string="trade context is busy";                                     break;
      case 147: error_string="expirations are denied by broker";                          break;
      case 148: error_string="amount of open and pending orders has reached the limit";   break;
      case 149: error_string="hedging is prohibited";                                     break;
      case 150: error_string="prohibited by FIFO rules";                                  break;
      //---- mql4 errors
      case 4000: error_string="no error (never generated code)";                          break;
      case 4001: error_string="wrong function pointer";                                   break;
      case 4002: error_string="array index is out of range";                              break;
      case 4003: error_string="no memory for function call stack";                        break;
      case 4004: error_string="recursive stack overflow";                                 break;
      case 4005: error_string="not enough stack for parameter";                           break;
      case 4006: error_string="no memory for parameter string";                           break;
      case 4007: error_string="no memory for temp string";                                break;
      case 4008: error_string="not initialized string";                                   break;
      case 4009: error_string="not initialized string in array";                          break;
      case 4010: error_string="no memory for array\' string";                             break;
      case 4011: error_string="too long string";                                          break;
      case 4012: error_string="remainder from zero divide";                               break;
      case 4013: error_string="zero divide";                                              break;
      case 4014: error_string="unknown command";                                          break;
      case 4015: error_string="wrong jump (never generated error)";                       break;
      case 4016: error_string="not initialized array";                                    break;
      case 4017: error_string="dll calls are not allowed";                                break;
      case 4018: error_string="cannot load library";                                      break;
      case 4019: error_string="cannot call function";                                     break;
      case 4020: error_string="expert function calls are not allowed";                    break;
      case 4021: error_string="not enough memory for temp string returned from function"; break;
      case 4022: error_string="system is busy (never generated error)";                   break;
      case 4050: error_string="invalid function parameters count";                        break;
      case 4051: error_string="invalid function parameter value";                         break;
      case 4052: error_string="string function internal error";                           break;
      case 4053: error_string="some array error";                                         break;
      case 4054: error_string="incorrect series array using";                             break;
      case 4055: error_string="custom indicator error";                                   break;
      case 4056: error_string="arrays are incompatible";                                  break;
      case 4057: error_string="global variables processing error";                        break;
      case 4058: error_string="global variable not found";                                break;
      case 4059: error_string="function is not allowed in testing mode";                  break;
      case 4060: error_string="function is not confirmed";                                break;
      case 4061: error_string="send mail error";                                          break;
      case 4062: error_string="string parameter expected";                                break;
      case 4063: error_string="integer parameter expected";                               break;
      case 4064: error_string="double parameter expected";                                break;
      case 4065: error_string="array as parameter expected";                              break;
      case 4066: error_string="requested history data in update state";                   break;
      case 4099: error_string="end of file";                                              break;
      case 4100: error_string="some file error";                                          break;
      case 4101: error_string="wrong file name";                                          break;
      case 4102: error_string="too many opened files";                                    break;
      case 4103: error_string="cannot open file";                                         break;
      case 4104: error_string="incompatible access to a file";                            break;
      case 4105: error_string="no order selected";                                        break;
      case 4106: error_string="unknown symbol";                                           break;
      case 4107: error_string="invalid price parameter for trade function";               break;
      case 4108: error_string="invalid ticket";                                           break;
      case 4109: error_string="trade is not allowed in the expert properties";            break;
      case 4110: error_string="longs are not allowed in the expert properties";           break;
      case 4111: error_string="shorts are not allowed in the expert properties";          break;
      case 4200: error_string="object is already exist";                                  break;
      case 4201: error_string="unknown object property";                                  break;
      case 4202: error_string="object is not exist";                                      break;
      case 4203: error_string="unknown object type";                                      break;
      case 4204: error_string="no object name";                                           break;
      case 4205: error_string="object coordinates error";                                 break;
      case 4206: error_string="no specified subwindow";                                   break;
      
      //--- original
      case 7001: error_string="trade timeout";                                            break;
      case 7002: error_string="trade is not allow";                                       break;
      default:   error_string="unknown error";
   }

   return(error_string);
}
