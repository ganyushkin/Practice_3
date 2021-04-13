library('shiny')               # создание интерактивных приложений
library('lattice')             # графики lattice
library('data.table')          # работаем с объектами "таблица данных"
library('ggplot2')             # графики ggplot2
library('dplyr')               # трансформации данных
library('lubridate')           # работа с датами, ceiling_date()
library('zoo')                 # работа с датами, as.yearmon()

# функция, реализующая API (источник: UN COMTRADE)
source("https://raw.githubusercontent.com/aksyuk/R-data/master/API/comtrade_API.R")

# Получаем данные с UN COMTRADE за период 2010-2020 года, по следующим кодам
code = c('0401', '0402', '0403', '0404', '0405', '0406')
df.comtrade = data.frame()
for (i in code){
  print(i)
  for (j in 2010:2020){
    Sys.sleep(5)
    s1 <- get.Comtrade(r = 'all', p = 643,
                       ps = as.character(j), freq = "M",
                       cc = i, fmt = 'csv')
    df.comtrade <- rbind(df.comtrade, s1$data)
    print(j)
  }
}
df.comtrade <- df.comtrade[, c(2, 4, 8, 10, 22, 30)]
# Загружаем полученные данные в файл, чтобы не выгружать их в дальнейшем заново
file.name <- paste('./data/un_comtrade.csv', sep = '')

write.csv(df.comtrade, file.name, row.names = FALSE)

write(paste('Файл',
            paste('un_comtrade.csv', sep = ''),
            'загружен', Sys.time()), file = './data/download.log', append=TRUE)

# Загружаем данные из файла
df.comtrade <- read.csv('./data/un_comtrade.csv', header = T, sep = ',')

# Оставляем  только те столбцы, которые понядобятся в дальше


df.comtrade

df1 <- data.frame(Year = numeric(), Trade.Flow = character(), 
                  Reporter = character(),  Netweight..kg. = numeric(), 
                  Period = character())
df2 <- data.frame(Year = numeric(), Trade.Flow = character(), 
                  Reporter = character(), Netweight..kg. = numeric(), 
                  Period = character())

for (m in month.name[1:6]){
  df1 <- rbind(df1, cbind(df.comtrade[str_detect(df.comtrade$Period.Desc., m), ], 
                          data.frame(Period = 'янв-авг')))
}
for (m in month.name[7:12]){
  df2 <- rbind(df2, cbind(df.comtrade[str_detect(df.comtrade$Period.Desc., m), ], 
                          data.frame(Period = 'сен-дек')))
}
df <- rbind(df1, df2)
df

file.name <- paste('./data/un_comtrade2.csv', sep = '')

write.csv(df, file.name, row.names = FALSE)

df <- read.csv('./data/un_comtrade2.csv', header=T, sep = ',')

# Код продукта, переменная для фильтра фрейма
commodity.code <- as.character(unique(df$Commodity.Code))
names(commodity.code) <- commodity.code
commodity.code <- as.list(commodity.code)
commodity.code

# Торговые потоки, переменная для фильтра фрейма
trade.flow <- as.character(unique(df$Trade.Flow))
names(trade.flow) <- trade.flow
trade.flow <- as.list(trade.flow)
trade.flow

df.filter <- df[df$Commodity.Code == commodity.code[1] &
                  df$Trade.Flow == trade.flow[2], ]

ggplot(df.filter, aes(y = Netweight..kg., group = Period, color = Period)) +
  geom_density() +
  coord_flip() + scale_color_manual(values = c('red', 'blue'),
                                    name = 'Период') +
  labs(title = 'График плотности массы поставок',
       y = 'Масса', x = 'Плотность')

# Запуск приложения
runApp('./comtrade_app', launch.browser = TRUE,
       display.mode = 'showcase')
