# Definição do negócio — HouseSearch

**Data:** 15 de julho de 2026

**Status:** proposta inicial para validação do piloto

**Mercado inicial:** corretores autônomos de Americana/SP e região

## Resumo

O HouseSearch reduz o trabalho manual de procurar imóveis em vários portais,
sites de imobiliárias e contatos dispersos. O corretor descreve o que o cliente
procura, confirma os critérios interpretados pelo assistente e recebe três
opções justificadas, com fonte, link e data da última verificação.

A promessa do MVP é entregar **três opções úteis em até dez minutos**. O produto
não substitui o corretor: organiza a pesquisa e fornece evidências para que ele
decida o que apresentar ao cliente.

## Problema

Um corretor recebe pedidos com preço, bairro, tipo, dormitórios e preferências
subjetivas. Para encontrar opções, ele repete filtros em diversos sites,
compara anúncios incompletos, elimina duplicatas e tenta lembrar quais páginas
já consultou. Esse processo é demorado, pouco rastreável e difícil de repetir.

## Cliente inicial

O primeiro cliente pagante é o **corretor autônomo** que atende compradores na
região de Americana/SP. Ele é um bom público inicial porque sente a dor com
frequência, decide sozinho sobre ferramentas de trabalho e consegue avaliar
rapidamente se uma shortlist é útil.

Compradores finais, equipes de imobiliárias, aluguel, captação de imóveis e CRM
completo não fazem parte do primeiro piloto.

## Trabalho que o produto resolve

> Quando um cliente me disser o imóvel que procura, quero consultar fontes
> confiáveis de uma só vez e receber as melhores opções explicadas, para que eu
> possa responder rápido sem passar horas pesquisando manualmente.

## Proposta de valor

- Uma conversa substitui a repetição dos mesmos filtros em vários sites.
- Cada recomendação mostra por que combina e em quais critérios deixa a desejar.
- Resultados exibem origem, link direto e momento da última verificação.
- A pesquisa continua em segundo plano sem bloquear o uso da aplicação.
- O corretor mantém a decisão final e pode refinar o atendimento por sete dias.

## Jornada principal

1. O corretor descreve o pedido do cliente em linguagem natural.
2. O assistente extrai critérios estruturados, faz no máximo uma pergunta de
   esclarecimento por vez e solicita confirmação.
3. A confirmação cria um atendimento e consome uma unidade da franquia.
4. A aplicação mostra resultados do índice local e atualiza fontes
   desatualizadas em segundo plano.
5. Regras determinísticas filtram, deduplicam e pontuam os anúncios.
6. O assistente explica os três primeiros usando somente dados comprovados.
7. O corretor marca as opções como úteis ou inadequadas e pode refinar o mesmo
   atendimento durante sete dias sem novo consumo.

## Modelo de receita

O modelo será **assinatura mensal com franquia de atendimentos e excedente**.
Uma unidade representa um pedido de cliente confirmado, incluindo refinamentos
durante sete dias. Mensagens, alterações de filtro e novas versões da shortlist
dentro dessa janela não consomem unidades adicionais.

### Experimento inicial de preço

- Teste assistido: 14 dias e até 10 atendimentos, sem cartão.
- Plano Fundador: R$ 149 por mês, com 30 atendimentos.
- Excedente: R$ 5 por novo atendimento.
- Cobrança do piloto: conferência mensal do ledger de uso e pagamento manual;
  checkout automático fica fora do MVP.

Esse preço é uma hipótese para entrevistar e vender, não uma conclusão de
mercado. Como referência de teto percebido, plataformas imobiliárias mais
amplas já anunciam planos a partir de R$ 229/mês, embora entreguem CRM, site e
gestão além da busca. A comparação serve apenas como contexto de disposição a
pagar, não como equivalência de produto: [planos Jetimob](https://www.jetimob.com/planos).

O preço será mantido somente se:

- o custo variável médio ficar abaixo de 20% da receita por atendimento;
- pelo menos três dos cinco corretores do piloto aceitarem pagar;
- a maioria relatar economia de tempo superior ao valor mensal cobrado.

## Piloto

O piloto terá cinco corretores e pelo menos cinquenta atendimentos reais. Uma
shortlist é considerada útil quando o corretor confirma que as três opções
podem ser apresentadas ao cliente, ainda que uma delas contenha ressalvas
explicitamente mostradas.

### Métrica principal

Pelo menos 70% dos atendimentos concluídos devem entregar três opções úteis em
até dez minutos após a confirmação dos critérios.

### Métricas auxiliares

- tempo até o primeiro resultado;
- tempo até a primeira shortlist completa;
- percentual de anúncios com preço, localização e link válidos;
- percentual de fontes consultadas com sucesso;
- duplicatas removidas por atendimento;
- opções encaminhadas ao cliente;
- custo de coleta e de LLM por atendimento;
- fontes que mais contribuem para opções úteis.

## Limites do MVP

Incluído:

- compra de imóveis residenciais em Americana/SP e região;
- corretores autônomos autenticados;
- fontes cadastradas apenas pelo administrador;
- busca híbrida, shortlist Top 3 e refinamento por sete dias;
- ledger de uso para cobrança manual;
- feedback simples sobre utilidade das recomendações.

Não incluído:

- aluguel, temporada e imóveis comerciais;
- comprador final como usuário;
- CRM, funil de vendas ou gestão de contratos;
- cadastro livre de fontes pelo corretor;
- checkout e emissão fiscal automáticos;
- aplicativo móvel nativo;
- publicação ou republicação dos anúncios.

## Riscos de negócio

| Risco | Como validar ou reduzir |
|---|---|
| Fontes bloqueiam ou proíbem coleta | Só ativar fontes aprovadas após revisar termos, robots.txt e alternativa oficial de integração |
| Anúncios desatualizados prejudicam confiança | Exibir última verificação, validar o link e retirar anúncios que falharem repetidamente |
| Três resultados não são realmente úteis | Coletar feedback por opção e revisar pesos do ranking semanalmente no piloto |
| LLM inventa atributos | Exigir evidência por campo e limitar a IA a explicar dados fornecidos pelo sistema |
| Corretor não aceita pagar R$ 149 | Fazer a oferta paga durante o piloto, não apenas pesquisa de opinião |
| Custo variável cresce com o uso | Registrar custo por job e chamada de LLM, impor limites e preferir extração determinística |

## Critério de continuidade

O produto avança para uma versão comercial quando cumprir simultaneamente:

1. cinquenta atendimentos reais concluídos;
2. 70% deles com três opções úteis em até dez minutos;
3. pelo menos três corretores dispostos a pagar o Plano Fundador;
4. custo variável abaixo de 20% da receita projetada;
5. ao menos três fontes estáveis e autorizadas contribuindo com resultados.

Se esses critérios não forem atingidos, a prioridade será corrigir cobertura e
qualidade dos dados antes de adicionar mais agentes, regiões ou funcionalidades.
