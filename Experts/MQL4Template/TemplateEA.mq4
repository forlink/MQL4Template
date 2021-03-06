#property strict
#property version   "1.00"


#define OPEN_POS 6
#define ALL_POS  7
#define PEND_POS 8
#define RETRY_INTERVAL 100 // msec
#define RETRY_TIME_LIMIT 5000 // msec


enum TRADE_SIGNAL
{
    BUY_SIGNAL = 1,
    SELL_SIGNAL = -1,
    NO_SIGNAL = 0
};


input double Lots = 0.1;
input int MagicNumber = 123;
input double TP = 100;
input double SL = 100;
input double Slippage = 1.0;


int TradeBar;
bool IsBuyTrade = true;
bool IsSellTrade = true;


int OnInit()
{
    TradeBar = true;
    HideTestIndicators(true);
    
    return(INIT_SUCCEEDED);
}


void OnTick()
{
    if (GetOrderCount(_Symbol, OPEN_POS, MagicNumber) == 0) {
        EntryProcess(_Symbol, Lots, Slippage, SL, TP, "", MagicNumber);
    } else {
        ExitProcess(_Symbol, Slippage, MagicNumber);
    }
}


void OnDeinit(const int reason)
{
    Comment("");
}


// エントリー処理の実行
void EntryProcess(
    const string symbol,
    const double lots,
    const double slippage,
    const double sl,
    const double tp,
    const string comment,
    const int magic)
{
    if (TradeBar == Bars) {
        return;
    }


    TRADE_SIGNAL entry_signal = GetEntrySignal();
    int trade_type = -1;
    double trade_price = 0;
    
    if (entry_signal == BUY_SIGNAL && IsBuyTrade == true) {
        trade_type = OP_BUY;
        trade_price = MarketInfo(symbol, MODE_ASK);
    } else if (entry_signal == SELL_SIGNAL && IsSellTrade == true) {
        trade_type = OP_SELL;
        trade_price = MarketInfo(symbol, MODE_BID);
    }
   
    if (trade_type == -1) {
        return;
    }
   

    int trade_result = EntryWithPips(
        _Symbol,
        trade_type,
        lots,
        trade_price,
        slippage,
        sl,
        tp,
        comment,
        magic);
    
    if (trade_result == 134 && IsTesting()) {
        IsBuyTrade = false;
        IsSellTrade = false;
    } else if (trade_result == 4110) {
        IsBuyTrade = false;
    } else if (trade_result == 4111) {
        IsSellTrade = false;
    }
    
    TradeBar = Bars;;
}


TRADE_SIGNAL GetEntrySignal()
{
    if (Close[1] > Open[1]) {
        return(BUY_SIGNAL);
    } else if (Close[1] < Open[1]) {
        return(SELL_SIGNAL);
    }
    return(NO_SIGNAL);
}


void ExitProcess(
    const string symbol,
    const double slippage,
    const int magic)
{
    if (GetExitSignal()) {
        Exit(symbol, slippage, magic);
    }
}


bool GetExitSignal()
{
    return(false);
}


int GetOrderCount(const string symbol, int type, int magic)
{
    int count = 0;

    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS)) {
            break;
        }
        if (OrderSymbol() != symbol || OrderMagicNumber() != magic) {
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


int Entry(
    const string symbol,
    const int type,
    double lots,
    double price,
    double slip,
    double sl,
    double tp,
    const string comment,
    const int magic)
{
    if (!IsTradeAllowed()) {
        return(7002);
    }

    int err = -1;
    int slippage = PipsToPoint(slip, symbol);
    color arrow = (type % 2 == 0) ? clrBlue : clrRed;
    int digits = (int)MarketInfo(symbol, MODE_DIGITS);
   
    lots = NormalizeLots(lots, symbol);
    price = NormalizeDouble(price, digits);
    sl = NormalizeDouble(sl, digits);
    tp = NormalizeDouble(tp, digits);
 
    uint starttime = GetTickCount();
    while (true) {
        if (GetTickCount() - starttime > RETRY_TIME_LIMIT) {
            Print("OrderSend timeout.");
            return(7001);
        }
      
        ResetLastError();
        RefreshRates();
      
        int ticket = OrderSend(
            symbol,
            type,
            lots,
            price,
            slippage,
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
        } else if (err == 130) {
            Print(
                "bid=", MarketInfo(symbol, MODE_BID), 
                " ask=", MarketInfo(symbol, MODE_ASK),
                " type=", TradeTypeToString(type), 
                " price=", price,
                " sl=", sl, " tp=", tp,
                " stoplevel=", MarketInfo(symbol, MODE_STOPLEVEL));
            break;
        } else if (err == 134) {
            break;
        } else if (err == 149) {
            break;
        } else if (err == 4110) {
            IsBuyTrade = false;
            break;
        } else if (err == 4111) {
            IsSellTrade = false;
            break;
        }
      
        Sleep(RETRY_INTERVAL);
    }
    return(err);
}


double NormalizeLots(double lots, string symbol)
{
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


int EntryWithPips(
    const string symbol,
    const int    type,
    const double lots,
    const double price,
    const double slip,
    const double slpips,
    const double tppips,
    const string comment,
    const int    magic)
{
    double sl = 0;
    double tp = 0;

    if (type == OP_SELL || type == OP_SELLLIMIT || type == OP_SELLSTOP) {
        if (slpips > 0) {
            sl = price + PipsToPrice(slpips, symbol);
        }
        if (tppips > 0) {
            tp = price - PipsToPrice(tppips, symbol);
        }
    } else {
        if (slpips > 0) {
            sl = price - PipsToPrice(slpips, symbol);
        }
        if (tppips > 0) {
            tp = price + PipsToPrice(tppips, symbol);
        }
    }
   
    return(Entry(symbol, type, lots, price, slip, sl, tp, comment, magic));
}


string TradeTypeToString(const int type)
{
    if (type > 5 || type < 0) {
        return("Invalid value");
    }
    
    string values[6] = {
        "OP_BUY",
        "OP_SELL",
        "OP_BUYLIMIT",
        "OP_SELLLIMIT",
        "OP_BUYSTOP",
        "OP_SELLSTOP"
    };
    
    return(values[type]);
}


bool Exit(const string symbol, const double slippage, const int magic)
{
    color arrow = clrNONE;
    int type;
    int slip = PipsToPoint(slippage, symbol);
   
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS)) {
            return(false);
        }
        if (OrderSymbol() != symbol || OrderMagicNumber() != magic) {
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
      
        if (result) {
            continue;
        }
      
        int err = GetLastError();
        Print("[OrderCloseError] : ", err, " ", ErrorDescription(err));
        if (err == 129) {
            break;
        }
        Sleep(RETRY_INTERVAL);
    }

    return(true);
}


double PipsToPrice(const double pips_value, const string symbol)
{
    double point = MarketInfo(symbol, MODE_POINT);
    int digits = (int)MarketInfo(symbol, MODE_DIGITS);
    double mult = (digits == 3 || digits == 5) ? 10.0 : 1.0;
    
    return(pips_value * point * mult);
}


int PipsToPoint(const double pips_value, const string symbol)
{
    int digits = (int)MarketInfo(symbol, MODE_DIGITS);
    int mult = (digits == 3 || digits == 5) ? 10 : 1;

    return((int)(pips_value * mult));
}


bool GetOrder(const string symbol, const int magic)
{
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            break;
        }
        if (OrderSymbol() != symbol || OrderMagicNumber() != magic) {
            continue;
        }
        return(true);
    }
    return(false);
}


string ErrorDescription(int error_code)
{
    string error_string;

    switch (error_code) {
        case 0:
        case 1:
            error_string = "no error";
            break;
        case 2:
            error_string = "common error";
            break;
        case 3:
            error_string = "invalid trade parameters";
            break;
        case 4:
            error_string = "trade server is busy";
            break;
        case 5:
            error_string = "old version of the client terminal";
            break;
        case 6:
            error_string = "no connection with trade server";
            break;
        case 7:
            error_string = "not enough rights";
            break;
        case 8:
            error_string = "too frequent requests";
            break;
        case 9:
            error_string = "malfunctional trade operation (never returned error)";
            break;
        case 64:
            error_string = "account disabled";
            break;
        case 65:
            error_string = "invalid account";
            break;
        case 128:
            error_string = "trade timeout";
            break;
        case 129:
            error_string = "invalid price";
            break;
        case 130:
            error_string = "invalid stops";
            break;
        case 131:
            error_string = "invalid trade volume";
            break;
        case 132:
            error_string = "market is closed";
            break;
        case 133:
            error_string = "trade is disabled";
            break;
        case 134:
            error_string = "not enough money";
            break;
        case 135:
            error_string = "price changed";
            break;
        case 136:
            error_string = "off quotes";
            break;
        case 137:
            error_string = "broker is busy (never returned error)";
            break;
        case 138:
            error_string = "requote";
            break;
        case 139:
            error_string = "order is locked";
            break;
        case 140:
            error_string = "long positions only allowed";
            break;
        case 141:
            error_string = "too many requests";
            break;
        case 145:
            error_string = "modification denied because order too close to market";
            break;
        case 146:
            error_string = "trade context is busy";
            break;
        case 147:
            error_string = "expirations are denied by broker";
            break;
        case 148:
            error_string = "amount of open and pending orders has reached the limit";
            break;
        case 149:
            error_string = "hedging is prohibited";
            break;
        case 150:
            error_string = "prohibited by FIFO rules";
            break;
      
        // mql4 errors
        case 4000:
            error_string = "no error (never generated code)";
            break;
        case 4001:
            error_string = "wrong function pointer";
            break;
        case 4002:
            error_string = "array index is out of range";
            break;
        case 4003:
            error_string = "no memory for function call stack";
            break;
        case 4004:
            error_string = "recursive stack overflow";
            break;
        case 4005:
            error_string = "not enough stack for parameter";
            break;
        case 4006:
            error_string = "no memory for parameter string";
            break;
        case 4007:
            error_string = "no memory for temp string";
            break;
        case 4008:
            error_string = "not initialized string";
            break;
        case 4009:
            error_string = "not initialized string in array";
            break;
        case 4010:
            error_string = "no memory for array\' string";
            break;
        case 4011:
            error_string = "too long string";
            break;
        case 4012:
            error_string = "remainder from zero divide";
            break;
        case 4013:
            error_string = "zero divide";
            break;
        case 4014:
            error_string = "unknown command";
            break;
        case 4015:
            error_string = "wrong jump (never generated error)";
            break;
        case 4016:
            error_string = "not initialized array";
            break;
        case 4017:
            error_string = "dll calls are not allowed";
            break;
        case 4018:
            error_string = "cannot load library";
            break;
        case 4019:
            error_string = "cannot call function";
            break;
        case 4020:
            error_string = "expert function calls are not allowed";
            break;
        case 4021:
            error_string = "not enough memory for temp string returned from function";
            break;
        case 4022:
            error_string = "system is busy (never generated error)";
            break;
        case 4050:
            error_string = "invalid function parameters count";
            break;
        case 4051:
            error_string = "invalid function parameter value";
            break;
        case 4052:
            error_string = "string function internal error";
            break;
        case 4053:
            error_string = "some array error";
            break;
        case 4054:
            error_string = "incorrect series array using";
            break;
        case 4055:
            error_string = "custom indicator error";
            break;
        case 4056:
            error_string = "arrays are incompatible";
            break;
        case 4057:
            error_string = "global variables processing error";
            break;
        case 4058:
            error_string = "global variable not found";
            break;
        case 4059:
            error_string = "function is not allowed in testing mode";
            break;
        case 4060:
            error_string = "function is not confirmed";
            break;
        case 4061:
            error_string = "send mail error";
            break;
        case 4062:
            error_string = "string parameter expected";
            break;
        case 4063:
            error_string = "integer parameter expected";
            break;
        case 4064:
            error_string = "double parameter expected";
            break;
        case 4065:
            error_string = "array as parameter expected";
            break;
        case 4066:
            error_string = "requested history data in update state";
            break;
        case 4099:
            error_string = "end of file";
            break;
        case 4100:
            error_string = "some file error";
            break;
        case 4101:
            error_string = "wrong file name";
            break;
        case 4102:
            error_string = "too many opened files";
            break;
        case 4103:
            error_string = "cannot open file";
            break;
        case 4104:
            error_string = "incompatible access to a file";
            break;
        case 4105:
            error_string = "no order selected";
            break;
        case 4106:
            error_string = "unknown symbol";
            break;
        case 4107:
            error_string = "invalid price parameter for trade function";
            break;
        case 4108:
            error_string = "invalid ticket";
            break;
        case 4109:
            error_string = "trade is not allowed in the expert properties";
            break;
        case 4110:
            error_string = "longs are not allowed in the expert properties";
            break;
        case 4111:
            error_string = "shorts are not allowed in the expert properties";
            break;
        case 4200:
            error_string = "object is already exist";
            break;
        case 4201:
            error_string = "unknown object property";
            break;
        case 4202:
            error_string = "object is not exist";
            break;
        case 4203:
            error_string = "unknown object type";
            break;
        case 4204:
            error_string = "no object name";
            break;
        case 4205:
            error_string = "object coordinates error";
            break;
        case 4206:
            error_string = "no specified subwindow";
            break;
      
        // original errors
        case 7001:
            error_string = "trade timeout";
            break;
        case 7002:
            error_string = "trade is not allow";
            break;
        
        default:
            error_string = "unknown error";
            break;
    }

    return(error_string);
}
