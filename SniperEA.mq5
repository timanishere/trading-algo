#property copyright "Copyright 2024, SniperEA"
#property version "1.00"

//--- Include this file to make placing trades easier to code
#include <trade/trade.mqh>

//-- Declare global variable
CTrade trade;

//--- Settings
double lot_size = 0.01;
int take_profit = 200;
int stop_loss = 100;
double buy_price_deviation = 0.00106;
double sell_price_deviation = 0.00106; // Increase to move away from price
int spread_range_min = 1;
int spread_range_max = 30;

//--- Initialise global variables
double buy_price_HL;
double sell_price_HL;

bool is_above_buy_price_lvl;
bool is_below_sell_price_lvl;

bool is_in_spread_range;

double take_profit_lvl;
double stop_loss_lvl;

//--- Declare datetime datatype
datetime
    //--- Set the date and time of when to trigger the EA to mark the levels
    trigger_start_time = D '2024.06.12 13:29:55',
    trigger_end_time = D '2024.06.12 13:29:59',

    //--- Initialise a variable for the current time
    current_time;

//--- Run when EA has been initilised
int OnInit()
{
    // Return message if function has successfully initialised
    Print("OnInit() succuessfully executed");
    return (INIT_SUCCEEDED);
}

// Run when de-initilised
void OnDeinit(const int reason)
{
    Print("OnDeinit() successfully executed: ", reason);
}

// Execute when the tick moves
void OnTick()
{
    //--- Get the local time from local machine
    current_time = TimeLocal();

    //--- Convert current time and trigger times into seconds. This is used to define the logic of when to place a trade
    long
        current_time_seconds = (long)current_time,
        trigger_start_time_seconds = (long)trigger_start_time,
        trigger_end_time_seconds = (long)trigger_end_time;

    Print("current_time: ", current_time);

    //--- Get total number of active trades
    int total_active_trades = PositionsTotal();
    Print("total_active_trades: ", total_active_trades);

    //--- Define the condition of when to make a mark the buy and sell levels on the chart.
    if (current_time_seconds >= trigger_start_time_seconds && current_time_seconds <= trigger_end_time_seconds)
    {

        //--- Mark buy and sell levels or the current chart using horizontal lines
        MarkBuyAndSellLvls();
        Print("Buy and sell levels have now been marked");
        Print("Marking complete");

        //--- Get the price of the buy price level that is marked on the chart
        buy_price_HL = ObjectGetDouble(0, "buy_price_lvl", OBJPROP_PRICE);
        Print("buy_price_HL: ", buy_price_HL);

        //--- Get the price of the sell price level that is marked on the chart
        sell_price_HL = ObjectGetDouble(0, "sell_price_lvl", OBJPROP_PRICE);
        Print("sell_price_HL: ", sell_price_HL);
    }

    //-- Get current bid and ask price
    double current_bid_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double current_ask_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    //--- Round the current bid and ask price to it's correct decimal place
    current_bid_price = NormalizeDouble(current_bid_price, _Digits);
    Print("current_bid_price: ", current_bid_price);

    current_ask_price = NormalizeDouble(current_ask_price, _Digits);
    Print("current_ask_price: ", current_ask_price);

    //--- Get current spread
    long current_spread = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
    Print("current_spread: ", current_spread);

    //--- Lets you know if current bid price is above the marked buy level. Set to false by default
    is_above_buy_price_lvl = false;

    //--- Check if current bid price is above buy price level
    if (current_bid_price > buy_price_HL && buy_price_HL != NULL)
    {
        is_above_buy_price_lvl = true;
    }

    Print("is_above_buy_price_lvl: ", is_above_buy_price_lvl);

    //--- Lets you know if current bid price is below the marked sell level. Set to false by default
    is_below_sell_price_lvl = false;

    //--- Check if current bid price is below sell price level
    if (current_bid_price < sell_price_HL && sell_price_HL != NULL)
    {
        is_below_sell_price_lvl = true;
    }

    Print("is_below_sell_price_lvl: ", is_below_sell_price_lvl);

    //--- Lets you know if current spread is in the spread range. Set to false by default
    is_in_spread_range = false;

    //--- Check if the current spread is within the spread range
    if (current_spread >= spread_range_min && current_spread <= spread_range_max)
    {
        is_in_spread_range = true;
    }

    Print("is_in_spread_range: ", is_in_spread_range);

    //--- Place a buy order when:
    //-- ** current price is above the buy price level,
    //-- ** current spread is in the range, and
    //-- ** There are no other active trades
    if (is_above_buy_price_lvl && is_in_spread_range && total_active_trades == 0)
    {

        //--- Define the take profit level for buying
        take_profit_lvl = current_ask_price + take_profit * _Point;

        //--- Define the stop loss level for buying
        stop_loss_lvl = current_ask_price - stop_loss * _Point;

        //--- Place a buy order
        trade.Buy(lot_size, _Symbol, current_ask_price, stop_loss_lvl, take_profit_lvl);

        Print("Buy order placed");
        Print("Bought at: ", current_ask_price);
        Print("take_profit_lvl: ", take_profit_lvl);
        Print("stop_loss_lvl: ", stop_loss_lvl);

        Print("EXPERT REMOVED");
        ExpertRemove();
    }

    //--- Place a sell order when:
    //-- ** current price is above the buy price level,
    //-- ** current spread is in the range, and
    //-- ** There are no other active trades
    if (is_below_sell_price_lvl && is_in_spread_range && total_active_trades == 0)
    {

        //--- Define the take profit level for buying
        take_profit_lvl = current_bid_price - take_profit * _Point;

        //--- Define the stop loss level for buying
        stop_loss_lvl = current_bid_price + stop_loss * _Point;

        //--- Place a sell order
        trade.Sell(lot_size, _Symbol, current_bid_price, stop_loss_lvl, take_profit_lvl);

        Print("Sell order placed");
        Print("Sold at: ", current_bid_price);
        Print("take_profit_lvl: ", take_profit_lvl);
        Print("stop_loss_lvl: ", stop_loss_lvl);

        Print("EXPERT REMOVED");
        ExpertRemove();
    }
}

void MarkBuyAndSellLvls()
{
    Print("Marking buy and sell levels on the chart...");

    //--- Define the buy price level
    double buy_price_lvl = SymbolInfoDouble(_Symbol, SYMBOL_ASK) + buy_price_deviation;

    //--- Define the sell price level
    double sell_price_lvl = SymbolInfoDouble(_Symbol, SYMBOL_BID) - sell_price_deviation;

    //--- Round the price of levels
    buy_price_lvl = NormalizeDouble(buy_price_lvl, _Digits);
    sell_price_lvl = NormalizeDouble(sell_price_lvl, _Digits);

    // -- Mark price levels for buying on the chart
    ObjectCreate(0, "buy_price_lvl", OBJ_HLINE, 0, 0, buy_price_lvl);
    ObjectSetInteger(0, "buy_price_lvl", OBJPROP_COLOR, clrYellow);
    ObjectSetInteger(0, "buy_price_lvl", OBJPROP_STYLE, STYLE_SOLID);

    // -- Mark price levels for selling on the chart
    ObjectCreate(0, "sell_price_lvl", OBJ_HLINE, 0, 0, sell_price_lvl);
    ObjectSetInteger(0, "sell_price_lvl", OBJPROP_COLOR, clrYellow);
    ObjectSetInteger(0, "sell_price_lvl", OBJPROP_STYLE, STYLE_SOLID);

    Print("buy_price_lvl: ", buy_price_lvl);
    Print("sell_price_lvl: ", sell_price_lvl);
    Print("Marking buy and sell levels complete");
}