
Convenção do projeto: Inspirada em AMPL, para distinguir tipos de objeto em código de modelagem matemática:

s_xxx: conjunto de índices.
xxx_yyy (snake_case): parâmetro do modelo.
XXX_YYY (UPPER_CASE): variável de decisão JuMP.

Isto desvia da convenção idiomática Julia (UPPER_CASE para constantes), mas a tradeoff foi feita conscientemente para preservar legibilidade de fórmulas como M_FLOW * unit_cost onde a estrutura matemática (variável × parâmetro) fica imediatamente legível.