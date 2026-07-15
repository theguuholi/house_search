# HouseSearch

HouseSearch é um assistente de pesquisa imobiliária para corretores autônomos. O
produto transforma o pedido de um cliente em uma shortlist explicada de três
imóveis, combinando um índice local com atualizações assíncronas de fontes
aprovadas.

## Estado do projeto

O projeto está na fase de **Spec-Driven Development**. A definição do negócio e
a arquitetura inicial devem ser revisadas antes da criação do plano de
implementação e antes de mudanças funcionais no código.

## Documentos principais

- [PRODUCT.md](PRODUCT.md): problema, público, proposta de valor, cobrança e
  critérios de validação.
- [ARCHITECTURE.md](ARCHITECTURE.md): SDD inicial, limites dos módulos, modelo
  de dados, fluxo híbrido, IA, jobs, segurança e estratégia de testes.

## Direção técnica

- Elixir, Phoenix e LiveView para o monólito modular e a experiência em tempo
  real.
- PostgreSQL/Ecto como fonte de verdade.
- Oban para coleta, atualização, retentativas e recomputação assíncrona.
- Sagents para interpretar pedidos, confirmar critérios e explicar a shortlist.
- Adaptadores explícitos para portais e sites de imobiliárias cadastrados pelo
  administrador.

## Desenvolvimento local

O projeto ainda preserva o scaffold Phoenix original. Os comandos de execução e
as dependências definitivas serão atualizados no plano de implementação depois
da aprovação do SDD.
