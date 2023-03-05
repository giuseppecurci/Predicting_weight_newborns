#0-Importing libraries ---- 
library(ggplot2)
library(dplyr)
library(lsr)

#1-Importing Data ----
data<-read.csv("https://raw.githubusercontent.com/giuseppecurci/Predicting_weight_newborns/main/neonati.csv")
attach(data)

#2/3-EDA ----
summary(data) 
table(Ospedale)   # Variabile indipend Ospedale: bilanciata
table(Sesso)      # variabile indipend sesso: bilanciata
table(Tipo.parto) # variabile indipend Tipo.parto: non bilanciata
table(Fumatrici)  # variabile indipend Fumatrici: non bilanciata

                     
ggplot(data = data)+               # Evidenzio sbilanciamento tra categorie
  geom_bar(aes(x=Fumatrici),              
           col= "black",
           fill= "blue")+
  theme_classic(base_size=10)

ggplot(data = data)+               # Evidenzio sbilanciamento tra categorie
  geom_bar(aes(x=Tipo.parto),
           col= "black",
           fill= "blue")+
  theme_classic(base_size=10)

ggplot(data=data)+                         # Apparentemente sembra solo esserci una differenza di variabilità
  geom_boxplot(aes(x=as.factor(Fumatrici),     
                   y=Peso,
                   fill=Sesso))


data %>%                          
  group_by(Fumatrici,Sesso)%>%          # Non emergono grosse differenze nella media e mediana    
  summarise(media=mean(Peso),           # Ma sembra esserci una grossa differenza di variabilità tra i Maschi(controllando per "Fumatrici")
            median=median(Peso),
            dev.st=sd(Peso))

Gestazione_class<-cut(Gestazione,       # Divisione per classi per facilitare interpretaz grafica(secondo criteri medici ufficiali)
                      breaks = c(0,37,43),               
                      labels = c("Prematuro","Maturo"))

data$Gestazione_class<- Gestazione_class

data %>%                          
  group_by(Tipo.parto,Sesso,Gestazione_class)%>%              
  summarise(media=mean(Peso),   
            dev.st=sd(Peso))


ggplot(data=data)+                               
  geom_boxplot(aes(x=as.factor(Gestazione_class),     
                   y=Peso,
                   fill=Sesso))+
  facet_grid(~Tipo.parto)

ggplot(data=data)+                         # Fumare sembra aumentare la durata della gestazione    
  geom_boxplot(aes(x=as.factor(Fumatrici), 
                   y=Gestazione,
                   fill=Tipo.parto))

data %>%                          
  group_by(Fumatrici,Sesso,Tipo.parto)%>%              
  summarise(media=mean(Gestazione),   
            dev.st=sd(Gestazione))

t.test(Peso~Fumatrici, data, alternative="greater")
t.test(Gestazione~Fumatrici, data, alternative="greater")

#4-Media peso di questio campione=media popolazione? ----

hist(Peso)                               #verifico normalità dei dati
stem(Peso) 
qqnorm(Peso,main = "Peso, Q-Q Plot")     #i dati sembrano essere normali, con skewness negativa
qqline(Peso)
moments::skewness(Peso)                  #0<skew<1 -> half-normal distribution
plot(density(Peso))
t.test(Peso,                             #medie differenti con p<0.01
       mu = 3250)

cohensD(Peso,mu = 3250)

hist(Lunghezza)                                  #verifico normalità dei dati
stem(Lunghezza)
qqnorm(Lunghezza, main = "Lunghezza, Q-Q Plot")
qqline(Lunghezza)                                #i dati sembrano essere normali, con forte skewness negativa
moments::skewness(Lunghezza)                     #skew>1 -> forse si tratta di una distribuzione lognormale ??
plot(density(Lunghezza))
t.test(Lunghezza,                                #medie differenti con p<0.01
       mu = 480)
cohensD(Lunghezza,mu = 480)


#5-Differenze tra sessi ----

lungh_M<-Lunghezza[Sesso=="M"]
lungh_F<-Lunghezza[Sesso=="F"]
t.test(lungh_M,                                #medie lung maschi maggiore con sig p<0.01
       lungh_F,
       alternative = "greater")
cohensD(Lunghezza~Sesso)                       #dimensione effetto

peso_M<-Peso[Sesso=="M"]
peso_F<-Peso[Sesso=="F"]
t.test(peso_M,                                 #medie peso maschi maggiore con sig p<0.05
       peso_F,
       alternative = "greater")
cohensD(Peso~Sesso)                      #dimensione effetto
                                                

hist(Cranio)                               #verifico normalità dei dati
stem(Cranio) 
qqnorm(Cranio,main = "Cranio, Q-Q Plot")   #i dati sembrano essere normali, con skewness negativa
qqline(Cranio)
moments::skewness(Cranio)                  #0<skew<1 -> half-normal distribution
plot(density(Cranio))

cranio_M<-Cranio[Sesso=="M"]
cranio_F<-Cranio[Sesso=="F"]
t.test(cranio_M,                           #medie dimensione cranio maschi maggiore con sig p<0.05
       cranio_F,
       alternative = "greater")
cohensD(Cranio~Sesso)                      #dimensione effetto

table_gestaz_sesso<-table(Gestazione_class,Sesso)
x<-chisq.test(table_gestaz_sesso)
x
x$expected
cramersV(table_gestaz_sesso)            #essendo due variabili qualitat, uso la V di Cramer
                                        #più vicino a 1->più forte è la correlazione tra le due variabili
#6-Differenze di Parti Cesarei tra Ospedali ----

table_parto_osped<-table(Tipo.parto, Ospedale)       #p-value>0.05, quindi si rifiuta l'ipotesi secondo cui ci sia una differenza significativa 
chisq.test(table_parto_osped)                        #nel numero di cesarei tra ospedali                
cramersV(table_parto_osped)

dummy_ces_nat<-ifelse(Tipo.parto == "Nat", 0, 1)
dummy_ospedale<-as.numeric(gsub("osp","",Ospedale))
cor(dummy_ces_nat, dummy_ospedale)                  

#ANALISI MULTIDIMENSIONALE ----
#1-Confusion Matrix ----

data$Ospedale<-as.numeric(gsub("osp","",Ospedale))
data$Tipo.parto<-as.numeric(ifelse(Tipo.parto == "Nat", 0, 1))    
data$Sesso<-as.numeric(ifelse(Sesso == "M",0,1))

panel.cor <- function(x, y, digits = 2, prefix = "", cex.cor, ...)
{
  usr <- par("usr"); on.exit(par(usr))
  par(usr = c(0, 1, 0, 1))
  r <- abs(cor(x, y))
  txt <- format(c(r, 0.123456789), digits = digits)[1]
  txt <- paste0(prefix, txt)
  if(missing(cex.cor)) cex.cor <- 0.8/strwidth(txt)
  text(0.5, 0.5, txt, cex = cex.cor * r)
}
pairs(data, lower.panel = panel.cor, upper.panel = panel.smooth,gap = 0)
cor(data)
#2-Regression con tutte le variabili ----

modello_0<-lm(Peso~. ,data)
summary(modello_0)

#3-Selezione delle variabili ----

car::vif(modello_0)        #tutti i valori sono abbondantemente sotto 4
n<-dim(data)[1]
modello_1<-MASS::stepAIC(modello_0,                                                  
              direction = "both",
              K= log(n))             #per usare BIC 

summary(modello_1)

modello_2<-update(modello_1, ~.-Tipo.parto)
summary(modello_2)

modello_3<-update(modello_2, ~.-N.gravidanze)
summary(modello_3)

modello_4<-update(modello_3, ~.-Ospedale)   
summary(modello_4)

modello_5<-update(modello_4, ~.-Sesso)
summary(modello_5)

modello_6<-update(modello_4, ~.-Gestazione) 
summary(modello_6)

modello_7<-update(modello_4, ~.-Gestazione_class) #modello migliore(o almeno così credevo prima di fare la diagnostica dei residui)
summary(modello_7)

BIC(modello_0,modello_1,modello_2,modello_3,modello_4,modello_5,modello_6,modello_7)
car::vif(modello_7)

#4-Interazioni/effetti non lineari? ----

interaction.plot(x.factor = Gestazione,  #es. di line chart per eff interazione
                 trace.factor = Sesso,   #come già detto le linee non si incrociano in modo preciso 
                 response = Peso,        #e risultano entrambe crescenti
                 fun = mean)

modello_7<-update(modello_7, ~.+I(Cranio^2)+I(Lunghezza^2))  #ovviamente non funziona

#5-Diagnostica residui ----

hist(modello_7$residuals)              
shapiro.test(residuals(modello_7))
par(mfrow=c(2,2))
plot(modello_7)                  #diversi problemi nei grafici, cambio modelli
par(mfrow=c(1,1))

lmtest::bptest(modello_7)        #Breusch-Pagan test: presente omoschedasticità

lmtest::dwtest(modello_7)        #Durbin-Watson Test: assente correlazione tra residui

lev<-hatvalues(modello_7)        #emergono svariati valori leverage, ad ogni modo i valori non sono necessariamente
plot(lev)                        #problematici fintanto che non sono siano sia leverage che outliers e con valori molto elevati
p<-sum(lev)
n<-length(lev)
soglia=2*p/n
abline(h=soglia,col=2)
lev[lev>soglia]

plot(rstudent(modello_7))
abline(h=c(-2,2))
car::outlierTest(modello_7)     #emergono 3 osservazioni, tra queste quelle più problematiche sono 1551 e 155(essendo anche outliers)

modello_log<-update(modello_7)  #trasformo la VD su scala log per provare a ridurre la variab(ma aumenta)
summary(modello_log)
par(mfrow=c(2,2))
plot(modello_log)
par(mfrow=c(1,1))

lmtest::bptest(x)                #non funziona, ancora p-value<0.01

#sospetto che le due osservazioni problematiche(1551 e 155) siano frutto di 
#di un qualche errore, indago più approfonditamente
                                                     
data_1551<-data[Gestazione==38,]        
summary(data_1551$Peso)

#usando i filtri nel dataset(3800<peso<4600, Sesso=F) emerge come la cosa più strana sia la lunghezza dell'osservazione
#1551 che di fatti è più bassa di tutte le altre osservazioni di ben 200cm.

modello_corretto<-update(modello_7, subset=-c(1551,155))
lmtest::bptest(modello_corretto)

hist(modello_corretto$residuals)              
shapiro.test(residuals(modello_corretto))     #ancora non normalità, ad ogni modo il Q-Q plot mostra  
par(mfrow=c(2,2))                             #normalità della distribuzione e il test è molto sensibile a dataset di grandi dimensioni(quindi ne ignoriamo il risultato)
plot(modello_corretto)                  
par(mfrow=c(1,1))
car::residualPlots(modello_corretto)

#6-Valutazione modello finale ----

car::vif(modello_corretto)
par(mfrow=c(2,2))
plot(modello_corretto)
par(mfrow=c(1,1))
summary(modello_corretto)

#7-Previsione su un neonato(no ecografia) ----

predict(modello_corretto, newdata = data.frame(Sesso=1,
                                               N.gravidanze=3,
                                               Gestazione=39,
                                               Lunghezza=mean(Lunghezza),    
                                               Cranio=mean(Cranio)))


#8-Rappresentazione Grafica modello ----

data = read.csv("https://raw.githubusercontent.com/giuseppecurci/Predicting_weight_newborns/main/neonati.csv")
data_clean<-data[-c(1551,155),] 

mod_rappresent<-update(modello_corretto,~.-Gestazione)

Gestazione_class<-cut(data_clean$Gestazione,
                      breaks = c(0,37,43),               #divisione per classi per facilitare interpretaz grafica(secondo criteri medici ufficiali)
                      labels = c("Prematuro","Maturo"))

data_clean$Gestazione_class<-Gestazione_class

ggplot(data=data_clean)+
  geom_point(aes(x=Lunghezza,
                 y=Peso,
                 col=as.factor(Sesso)))+
  geom_smooth(aes(x=Lunghezza,
                  y=Peso,
                  col=as.factor(Sesso)),se=F,method = "lm")+
  facet_grid(~Gestazione_class)                          

ggplot(data=data_clean)+
  geom_point(aes(x=Lunghezza,
                 y=Peso,
                 col=as.factor(Sesso)))+
  geom_smooth(aes(x=Lunghezza,
                  y=Peso,
                  col=as.factor(Sesso)),se=F,method = "lm")
