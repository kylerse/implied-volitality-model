% ======================== Part One: Load data ===========================
% Note that I only use a part of the dataset, specifically the 180ETF
% contract is used, beacuse it has the most samples. Here I used a small 
% piece python script (about time lines) to clean the date, final result 
% is stored at 180ETF.xlsx.
% 
% Important and essential informations are all contained such as
%     key: unique identification for each item.  
%        - Sample: 209000001812110001032015-01-09 
%     ShortName: A brief Chinese name for every contract.
%        - Sample: 180ETF¹Á3ÔÂ3400, ¹Á-put, ¹º-call.
%     CallOrPut: Option type.
%        - 1: call, 0: put
%     RemainingTerm: the time left before maturity
%        - Sample: 0.127, unit: year
%     ExerciseDate: The maturity date.
%     TradingDate: All the price, volumn, volatility are collected on this day. 
%     HistoricalVolatility/ImpliedVolatility
%     OpenPrice/ClosePrice/HighPrice/LowPrice
%     ....
% All data are download from CSMAR, academic use only.

dataFile = './data/180ETF.xlsx';    % set file path
[data,text] = xlsread(dataFile);    % load data
OptionType =  data(:,1);         
Strike = data(:,2);
UnderlyingScrtClose = data(:,5);
RemainingTerm = data(:,6);
HistoricalVolatility = data(:,8);
ImpliedVolatility = data(:,9);
OptionPrice = data(:,13);
OpenPrice = data(:,10);
Moneyness = Strike./UnderlyingScrtClose;
OptionName = text(2:end,2);
TradingDateStr = datestr(text(2:end,8));
TradingDateNum = datenum(TradingDateStr);

% =======================================================================



% ====================== Part Two: Clean Data =========================== 
% The project intend to analyze the mechanism of implied volatility, this
% task highly rely on high quality data, so a filtration and clean is
% necessary. Here are some assumptions while we choose data:
%   1. Any contract that have too few trading volumn is invalid. Say, if
%   trading  volumn is less than 10, we don't use it. 
%   2. After (1), any date that has no more that three type maturity is
%   invalid. Because we want to fit the implied volatility surface, this
%   condition is compulsory, otherwise, it will be definitely overfitted. 
%   3. Any contract with abnormal implied volatility is invalid. We ignore
%   some very strange data, most of them are at near maturity.
% 
%   PS. Some procedures are done in python script clean.py for convenience.


Dates = unique(TradingDateNum);
labels = ones(length(Dates),1);
for i=1:length(Dates)
    cond = (TradingDateNum == Dates(i));
    if sum(cond)<6
        labels(i) = 0;
    end
    Ndate = length(unique(RemainingTerm(cond)));
    if Ndate <3
        labels(i) = 0;
    end
end
validDate = Dates(labels==1);
% =======================================================================



% ================== Part Three: Fit the Surface ======================== 
% This part mainly fucons on one job, to fit the surface and store the
% parameters. More work is done, however, here the final version is
% presented. One biggest question here is to choose the model.
% Simple models can't capture the characteristic while complicated models
% are easily overfitted. So several caondidates are considered.
% Those are:
%    (1) sigma(m, t) = beta1 + beta2 * m + beta3 * t 
%    (2) sigma(m, t) = beta1 + beta2 * m + beta3 * m^2
%    (3) sigma(m, t) = beta1 + beta2 * m + beta4 * t + beta3 * m^2  
%    (4) sigma(m, t) = beta1 + beta2 * m + beta3 * t + beta4 * t^2
%    (5) sigma(m, t) = beta1 + beta2 * m + beta3 * t + beta4 * t^2 + beta4 * m^2
%  * (6) sigma(m, t) = beta1 + beta2 * m + beta3 * t + beta4 * m^2 
%                        + beta5 * t * m + beta6 * t^2
%    (7) sigma(m, t) = beta1 + beta2 * m + beta3 * t + beta4 * m^2 
%                        + beta5 * t * m + beta6 * t^2 + beta7 * m^3 
%                        + beta8 * t^3 + beta9 * t * m^2 +beta10 * m * t^2
%     ...
% Consider both simplicity and accuracy, we choose model (6).

observations = length(validDate);
p1 = zeros(observations,1);
p2 = zeros(observations,1);
p3 = zeros(observations,1);
p4 = zeros(observations,1);
p5 = zeros(observations,1);
p6 = zeros(observations,1);
for i=1: observations
    cond = (TradingDateNum == validDate(i));
    x = Moneyness(cond);
    z = ImpliedVolatility(cond);
    y = RemainingTerm(cond);
    sf = fit([x, y],z,'poly22');
    plot(sf,[x,y],z);
    xlabel('Moneyness')
    ylabel('maturity')
    zlabel('Imp.Vol')
    axis([0.8 1.25 0 0.5 0.05 0.55]);
    pause(0.1);
    p1(i) = sf.p00;
    p2(i) = sf.p10;
    p3(i) = sf.p01;
    p4(i) = sf.p20;
    p5(i) = sf.p11;
    p6(i) = sf.p02; 
end

surface = @(x, y,p1,p2,p3,p4,p5,p6)p1 + p2*x + p3*y + p4*x^2 + p5*x*y + p6*y^2;

mn=[0.8:0.001:1.2];
for i=1:401
mn(i)=surface((i-1)/1000+0.8,0.3,p1(202),p2(202),p3(202),p4(202),p5(202),p6(202));
end
plot(xmn,mn);
xlabel('Moneyness')
ylabel('Implied Volatility')

% =======================================================================


% ================== Part Three: Trading Strategy ======================== 
% This part develops a trading stratagy based on the estimated surface,
% since we know implied volatility reflect how expensive a option is, we
% can long those under-estimated ones and short those over-estimated ones,
% that is, we buy those contract that over the fitted surface and sell the
% contract under the surface. 
% Note we only trade a part of contracts. And positions are cleared daily.

valueNow = 1; % initial money
values = [];
for obs=1:420
    cond = (TradingDateNum == validDate(obs));
    condNext = (TradingDateNum == validDate(obs+1));
    x = Moneyness(cond);
    z = ImpliedVolatility(cond);
    y = RemainingTerm(cond);
    price = OptionPrice(cond);
    name = OptionName(cond);
    nameNext = OptionName(condNext);
    priceNext = OptionPrice(condNext);
    common = zeros(size(x));
    common2 = zeros(size(nameNext));
    for i=1:length(common)
        common(i) = (any(nameNext == string(name(i))));
    end
    for i=1:length(common2)
        common2(i) = (any(name == string(nameNext(i))));
    end
    common=boolean(common);
    common2=boolean(common2);

    [a_, index] = sort(name(common));
    [a_, index2] = sort(nameNext(common2));
    price = price(common);
    priceNext = priceNext(common2);
    price = price(index);
    priceNext = priceNext(index2);
    
    long = zeros(size(common));
    for i=1:length(common)
        long(i) = common(i) * (-1 + 2 * (z(i)<surface(x(i),y(i),p1(obs),p2(obs),p3(obs),p4(obs),p5(obs),p6(obs))));
    end
    longShortType = long(long~=0);
    UnitShort = -(0.5*abs(valueNow)/sum(longShortType==-1))*(longShortType==-1);
    UnitLong = (1*abs(valueNow)/sum(longShortType==1))*(longShortType==1);
    position = (UnitShort + UnitLong)./price+0.01;
    if all([length(longShortType)>10,sum(common)==sum(common2),length(UnitShort)>8,length(UnitLong)>8])
        valueNow = sum(position.*priceNext)-sum(position.*price) + valueNow
    end
    values = [values valueNow];
end
plot(validDate(2:end),values)
dateaxis('x',2);
xlabel('date')
ylabel('net value')
drawdown = zeros(length(values),1)
HistoricalMax = values(1)
for i=10:length(drawdown)
    drawdown(i) = max(max(values(i-9:i-1))-values(i),0);
end

%cond = ((OptionType==1)&(Moneyness>=1))|((OptionType==0)&(Moneyness<=1));
%Moneyness = Moneyness(cond);
%ImpliedVolatility = ImpliedVolatility(cond);
%RemainingTerm = RemainingTerm(cond);
%DateNumber = DateNumber(cond);
%OptionType = OptionType(cond);





valueNow = 1; % initial money
values = [1];
for obs=1:420
    cond = (TradingDateNum == validDate(obs+1));
    %condNext = (TradingDateNum == validDate(obs+1));
    x = Moneyness(cond);
    z = ImpliedVolatility(cond);
    y = RemainingTerm(cond);
    price = OptionPrice(cond);
    openprice = OpenPrice(cond);
    long = zeros(size(price));
    for i=1:length(price)
        long(i) = 1 * (-1 + 2 * (z(i)<surface(x(i),y(i),p1(obs),p2(obs),p3(obs),p4(obs),p5(obs),p6(obs))));
    end
    longShortType = long(long~=0);
    UnitShort = -0.01 * (longShortType==-1);
    UnitLong = (0.2*abs(valueNow)/sum(longShortType==1))*(longShortType==1);
    position = (UnitShort + UnitLong)./(power(openprice,0.5)+0.01);
    if ~all(isnan(UnitLong))
        valueNow = sum(position.*price)-sum(position.*openprice) + valueNow
    end
    values = [values valueNow];
end
plot(validDate(2:end),values(1:end-1))
dateaxis('x',2);
xlabel('date')
ylabel('net value')













