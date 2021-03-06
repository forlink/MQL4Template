//+------------------------------------------------------------------+
//|                                                         MQL4.mqh |
//|                                 Copyright 2018, Keisuke Iwabuchi |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Keisuke Iwabuchi"
#property strict


enum ENUM_MQL4_PROGRAM_TEMPLATE_MODE
{
    TEMP_EA = 1,
    TEMP_EA_SAR = 2,
    TEMP_EA_NOTHING_POS_COUNT_LIMIT = 3,
    TEMP_INDICATOR = 100
};


class MQL4
{
    private:
        string symbol;
        double point;
        int digits;
        int mult;
        int trade_bar;
        int gmt_shift;
        int object_count;
        bool is_trade;
        bool is_buy_trade;
        bool is_sell_trade;
        
        void SetPoint(const string value);
        void SetDigits(const string value);
        void SetMult(const string symbol_value, const string company, const int digits_value);
        void CheckUpEA();
    
    public:
        MQL4(ENUM_MQL4_PROGRAM_TEMPLATE_MODE mode = TEMP_EA);
        ~MQL4(void);
        
        void SetSymbol(const string value);
        string GetSymbol(void);
        double GetPoint(void);
        int GetDigits(void);
        void SetTradeBar(const int value);
        int GetTradeBar(void);
        int GetMult(void);
        void SetFalseIsTrade(void);
        bool GetIsTrade(void);
        void SetGMTShift(const int value);
        int GetGMTShift(void);
        void SetFalseIsBuyTrade(void);
        bool GetIsBuyTrade(void);
        void SetFalseIsSellTrade(void);
        bool GetIsSellTrade(void);
};


void MQL4::SetPoint(const string value)
{
    this.point = MarketInfo(value, MODE_POINT);
}


void MQL4::SetDigits(const string value)
{
    this.digits = (int)MarketInfo(value, MODE_DIGITS);
}


void MQL4::SetMult(const string symbol_value,const string company,const int digits_value)
{
    this.mult = (digits_value == 3 || digits_value == 5) ? 10 : 1;
    
    // EZインベスト証券 USDJPY 4桁対応
    if  (company == "EZ Invest Securities Co., Ltd." &&
        StringSubstr(symbol_value, 0, 6) == "USDJPY") {
        this.mult = 100;
    }
}


void MQL4::CheckUpEA(void)
{
    #ifdef DEVELOP_MODE
    if (!IsTesting()) {
        ExpertRemove();
    }
    #endif

    // 口座のチェックアップ
    //--- ターミナルの自動売買の許可を確認
    if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) {
        Alert("自動売買が許可されていません。MT4のオプションを開き、"
            + "「自動売買を許可する」がチェックされているか確認して下さい。");
    } else if (!MQLInfoInteger(MQL_TRADE_ALLOWED)) {
        Alert("自動売買が許可されていません。エキスパートアドバイザーの設定を開き、"
            + "全般タブにて「自動売買を許可する」にチェックを入れて下さい。");
    }
   
    //--- 口座の自動売買の許可を確認
    if (!AccountInfoInteger(ACCOUNT_TRADE_EXPERT)) {
        Alert("このアカウントは自動売買が許可されていません。");
    }
    if (!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)) {
        Alert("このアカウントは自動売買が許可されていません。");
    }
   
    // インジケーターを非表示
    HideTestIndicators(true);
}


MQL4::MQL4(ENUM_MQL4_PROGRAM_TEMPLATE_MODE mode = TEMP_EA)
{
    this.SetSymbol(_Symbol);
    this.trade_bar = Bars;
    this.is_trade = true;
    this.object_count = 0;
    this.gmt_shift = 2;
    this.is_buy_trade = true;
    this.is_sell_trade = true;
    
    if (mode == TEMP_EA) {
        this.CheckUpEA();
    }
}


MQL4::~MQL4(void)
{
    if (!IsVisualMode()) {
        Comment("");
      
        for (int i = 0; i < this.object_count; i++) {
            ObjectDelete(0, "Obj" + IntegerToString(i));
        }
    }
}


void MQL4::SetSymbol(const string value)
{
    if (StringLen(value) > 0) {
        this.symbol = value;
        this.SetPoint(value);
        this.SetDigits(value);
        this.SetMult(value, AccountCompany(), this.digits);
    }
}


string MQL4::GetSymbol(void)
{
    return(this.symbol);
}


double MQL4::GetPoint(void)
{
    return(this.point);
}


int MQL4::GetDigits(void)
{
    return(this.digits);
}


void MQL4::SetTradeBar(const int value)
{
    if (value >= 0) {
        this.trade_bar = value;
    }
}


int MQL4::GetTradeBar(void)
{
    return(this.trade_bar);
}


int MQL4::GetMult(void)
{
    return(this.mult);
}


void MQL4::SetFalseIsTrade(void)
{
    this.is_trade = false;
}


bool MQL4::GetIsTrade(void)
{
    return(this.is_trade);
}


void MQL4::SetGMTShift(const int value)
{
    if (0 <= value && value <= 23) {
        this.gmt_shift = value;
    }
}


int MQL4::GetGMTShift(void)
{
    return(this.gmt_shift);
}


void MQL4::SetFalseIsBuyTrade(void)
{
    this.is_buy_trade = false;
}


bool MQL4::GetIsBuyTrade(void)
{
    return(this.is_buy_trade);
}


void MQL4::SetFalseIsSellTrade(void)
{
    this.is_sell_trade = false;
}


bool MQL4::GetIsSellTrade(void)
{
    return(this.is_sell_trade);
}
