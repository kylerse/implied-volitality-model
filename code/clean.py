# -*- coding: utf-8 -*-
"""
Created on Tue Jun  5 17:01:51 2018

@author: kai
"""
import pandas as pd
import os
os.chdir('C:\\Users\\kai\\Desktop\\project')
parameter = pd.read_excel('./data/SO_PricingParameter.xlsx')
trading = pd.read_excel('./data/SO_QuotationBas.xlsx')

target = ['key','ShortName', 'ExchangeCode', 'CallOrPut', 'StrikePrice', 
          'ExerciseDate', 'TradingDate', 'UnderlyingScrtClose', 'RemainingTerm',
          'RisklessRate','HistoricalVolatility', 'ImpliedVolatility']

parameter = parameter[target]


target2 = ['key', 'OpenPrice', 'HighPrice', 'LowPrice', 'ClosePrice', 
           'SettlePrice', 'Volume', 'Position', 'Amount']

trading = trading[target2]

merged = pd.merge(parameter,trading,on='key')

valid = merged[(merged['HistoricalVolatility']*0.4<merged['ImpliedVolatility'])&
       (merged['ImpliedVolatility']<merged['HistoricalVolatility']*1.6)&
       (merged['Volume']>5)]

valid.to_excel('./data/option_data.xlsx')