import requests, os, random, shutil
import numpy as np
import pandas as pd
from pandas import ExcelWriter
from bs4 import BeautifulSoup
from time import sleep
from pprint import pprint

def nss(coef: list, dias):
    """
    Função que calcula as curvas de juros futuros anuailizadas e discretas para os cupons pré, ipca, igpm e tr,
    utilizando o modelo NelsonSiegelSvensson.

    Obs.: Os coeficientes do modelo são obtidos no site da SUSEP na primeira semana de todo mês

    y = x/252
    t = exp(y) - 1

    x: dias úteis (base de 252 dias úteis)
    y: taxa de juros futuros contínua
    t: taxa de juros futuros discreta
    """

    termo_1 = (coef[0]) + (coef[1] * ((1.0-np.exp(-dias*coef[4])) / (dias*coef[4])))
    termo_2 = (coef[2]*((((1.0-np.exp(-dias*coef[4])) / (dias*coef[4]))) - (np.exp(-dias*coef[4]))))
    termo_3 = (coef[3]*((((1.0-np.exp(-dias*coef[5])) / (dias*coef[5]))) - (np.exp(-dias*coef[5]))))

    return np.exp(termo_1 + termo_2 + termo_3) - 1



def lista_anomes(links):
    """
    Extrai, ordena e retira dupicados de anomes(aaaamm) da lista de links inserida.
    Retornando uma lista com os anomes ordenados.
    """
    lista_anomes_duplic = list()
    for i in range(len(links)):
        anomes = links[i].split(".tx")[0][-6:]
        lista_anomes_duplic.append(anomes)
    lista_anomes =  set(lista_anomes_duplic)
    lista_anomes = sorted(list(lista_anomes), reverse = True)

    return lista_anomes



def clean_and_join(links, anomes):
    """
    Baixa cada um dos coeficientes da SUSEP e da ANBIMA.
    Efetua a limpeza de cada um dos coeficientes, agrupando em um único dataframe em .csv
    """
    for i in list(range(0,len(links))):
        anomes_data = links[i].split(".tx")[0][-6:]
        n = links.index(links[i])
        print('Tratando coeficientes de ' + anomes_data + ' ...')
        if (n % 2 == 0):
            trata_coef_susep(links[i], anomes_data)
        else:
            trata_txt_anbima(links[i], anomes_data)
        print('Coeficientes de ' + anomes_data + ' tratados')
        print('\n')

    for i in anomes:
        s = pd.read_csv('coef_susep_{}.csv'.format(i), sep = ";", usecols=[1,2])
        a = pd.read_csv('coef_anb_{}.csv'.format(i), sep = ";", usecols=[0,1,2])
        coef = a.join(s)
        # coef = s.merge(a, left_index= True, right_index= True)
        coef.to_csv("coef_{}.csv".format(i), sep = ";", index= False)

    sleep(random.randint(1,3))



def trata_coef_susep(link, anomes: str):
    coef = pd.read_csv(link, sep = ";", encoding = "ISO-8859-1")
    coef.drop("data.base", 1, inplace = True)
    coef.set_index('tipo', inplace = True)        # Seta como index do dataframe a variável que contem os nomes dos coeficientes

    coef = coef.transpose()

    if int(anomes) >= 201603:
        coef.drop("Cupom Cambial", 1, inplace = True)
    else:
        coef.drop("Cupom Cambial", 1, inplace = True)
        coef.drop("Cupom de IPCA", 1, inplace = True)
        coef.drop("PRÉ-FIXADA", 1, inplace = True)

    coef.iloc[3,coef.columns.get_loc("Cupom de TR")] = 0          # Ajusta os coeficientes fixos da curva tr
    coef.iloc[5,coef.columns.get_loc("Cupom de TR")] = 1

    coef.columns = ['igpm', 'tr']            # Renomeia as colunas dos dataframes

    coef.to_csv("coef_susep_{}.csv".format(anomes), sep = ";")

    sleep(random.randint(1,3))



def trata_txt_anbima(link, anomes: str):
    # s = requests.Session()
    # s.proxies = {'https': 'https://177.25.204.75'}
    txt_anbima = requests.get(link).text                # lê o arquivo .txt da curva e extrai seu conteúdo como texto

    coef_anbima = txt_anbima.split("\n")[2:5]           # Seleciona as 3 linhas correspondentes aos coeficientes e seus nomes

    names = coef_anbima[0].split("@")[2:]               # Separa em novas listas novamente pelo @ e retira as duas primeiras observações de cada lista
    pre = coef_anbima[1].split("@")[2:]
    ipca = coef_anbima[2].split("@")[2:]

    names = [sub.replace("\r","") for sub in names]        # Retira os caracteres ruins de cada elemento das listas
    pre = [sub.replace("\r","") for sub in pre]
    ipca = [sub.replace("\r","") for sub in ipca]

    pre = [sub.replace("E-02","e-02") for sub in pre]      # Adequa a notação científica para fazer a
    ipca = [sub.replace("E-02","e-02") for sub in ipca]    # conversão adequada de string para float (numérico)

    pre = [float(p) for p in pre]                          # Faz a conversão de string para número
    ipca = [float(i) for i in ipca]

    valores = {"prefixado": pre, "ipca": ipca}             # Estrutura o objeto dicionário para criar o dataframe
    df = pd.DataFrame(valores, index = names, columns = ["prefixado","ipca"])      # Cria o dataframe
    df = df.rename(index = {'Beta 1': 'beta.0', 'Beta 2':'beta.1', 'Beta 3':'beta.2', 'Beta 4':'beta.3', 'Lambda 1':'lambda.1', 'Lambda 2':'lambda.2'})

    df.to_csv("coef_anb_{}.csv".format(anomes), sep = ";")

    sleep(random.randint(1,3))



#  inputs
base_dir = "C:/Users/augus/Documents/dev_Py/Py/ETTJ_SUSEP/testes"      # diretório base
nperiodos = 1401
URL = "http://www.susep.gov.br/setores-susep/cgsoa/coris/dicem/modelo-de-interpolacao-e-extrapolacao-da-ettj"
headers = {"User-Agent" : "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36"}

os.chdir(base_dir)
# Faz a requisição da pagina web e extrai o html em um objeto BeautifulSoup
page = requests.get(URL, headers=headers)
soup = BeautifulSoup(page.content, 'html.parser')

# gera uma lista com todos as tags 'a' e extrai uma lista com todos os links
arq_txts = list(soup.find('table').find_all('a'))
links = [i.get('href') for i in arq_txts]

# remove os elementos 'None' da lista e separa os links em 3 arquivos para as requisicoes
for i in links:
    if (i == None):
        links.remove(i)
links_a = links[0:34]
links_b = links[34:68]
links_c = links[68:]

# extrai os anomes dos links como lista e separa em 3 arquivos para as requisicoes
anomes = lista_anomes(links)
anomes_a = anomes[:17]
anomes_b = anomes[17:34]
anomes_c = anomes[34:]

# extrai os coeficietes dos links, limpa e agrupa de acordo com cada anomes e curva
clean_and_join(links_a, anomes_a)
clean_and_join(links_b, anomes_b)
clean_and_join(links_c, anomes_c)

############## Geração das curvas ##############
nseq = list(range(0, nperiodos))      # cria uma sequencia de 0 a 'nperiodos'

dias = (np.arange(start = 21.0, stop = (nperiodos*21), step = 21.0) / 252.0)
dias = np.insert(dias, 0, (1.0/252.0))        # Lista com os inputs do modelo NelsonSiegelSvensson

base_df = {
"nseq": nseq,
"dias": dias*252
 }

df_ipca = pd.DataFrame(base_df)
df_pre = pd.DataFrame(base_df)
df_igpm = pd.DataFrame(base_df)
df_tr = pd.DataFrame(base_df)

for i in anomes[::-1]:
    coeficientes = pd.read_csv('coef_{}.csv'.format(i), sep = ";")

    curva_ipca = nss(coeficientes["ipca"], dias)
    curva_ipca = pd.Series(curva_ipca, name = "{}".format(i))
    df_ipca['{}'.format(i)] = curva_ipca
    print('curva ipca de ' + curva_ipca.name + ' gerada')

    curva_pre = nss(coeficientes["prefixado"], dias)
    curva_pre = pd.Series(curva_pre, name = "{}".format(i))
    df_pre['{}'.format(i)] = curva_pre
    print('curva pre de ' + curva_pre.name + ' gerada')

    curva_igpm = nss(coeficientes["igpm"], dias)
    curva_igpm = pd.Series(curva_igpm, name = "{}".format(i))
    df_igpm['{}'.format(i)] = curva_igpm
    print('curva igpm de ' + curva_igpm.name + ' gerada')

    curva_tr = nss(coeficientes["tr"], dias)
    curva_tr = pd.Series(curva_tr, name = "{}".format(i))
    df_tr['{}'.format(i)] = curva_tr
    print('curva tr de ' + curva_tr.name + ' gerada')


writer = ExcelWriter(base_dir + '/historico_curvas.xlsx')
df_pre.to_excel(writer, "curvas_pre", index = False)
df_ipca.to_excel(writer, "curvas_ipca", index = False)
df_igpm.to_excel(writer, "curvas_igpm", index = False)
df_tr.to_excel(writer, "curvas_tr", index = False)
writer.save()

if 'coeficientes' in os.listdir():
    shutil.rmtree(base_dir + '/coeficientes')
    os.mkdir('coeficientes')
else:
    os.mkdir('coeficientes')

for i in os.listdir():
    if i.startswith('coef_susep_') or i.startswith('coef_anb_'):
        os.remove(i)
    if i.startswith('coef_20'):
        shutil.move(i, 'coeficientes/' + i)

print('\n\n')
print("#"*10 + " Histórico das curvas finalizado " + "#"*10)
print('O arquivo ' + 'historico_curvas.xlsx ' + 'está no caminho: ' + '\n' + base_dir)
print('Os coeficientes de cada anomes estão no caminho: ' + '\n' + base_dir + '/coeficientes')
print("\n")
