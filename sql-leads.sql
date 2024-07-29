-- (Query 1) Gênero dos leads
-- Colunas: gênero, leads(#)

with
	customerid_gender as (	
		select
			cus.customer_id,
			ibge.gender
		from sales.customers as cus
		left join temp_tables.ibge_genders as ibge
			on lower(cus.first_name) = ibge.first_name
	)

select distinct
	customerid_gender.gender,
	count(fun.visit_page_date) as leads
from sales.funnel as fun
left join customerid_gender
	on fun.customer_id = customerid_gender.customer_id
group by customerid_gender.gender



	
select
	case
		when ibge.gender = 'male' then 'homem'
		when ibge.gender = 'female' then 'mulher'
		end as "genero",
	count(*) as "leads (#)"
from sales.customers as cus
left join temp_tables.ibge_genders as ibge
	on lower(cus.first_name) = ibge.first_name
group by ibge.gender

-- (Query 2) Status profissional dos leads
-- Colunas: status profissional, leads (%)

select
	case
		when professional_status = 'freelancer' then 'freelancer'
		when professional_status = 'clt' then 'clt'
		when professional_status = 'retired' then 'aposentado(a)'
		when professional_status = 'self_employed' then 'autonomo'
		when professional_status = 'other' then 'outro'
		when professional_status = 'businessman' then 'empresario(a)'
		when professional_status = 'civil_servant' then 'funcionario publico'
		when professional_status = 'student' then 'estudante'
		end as "status profissional",
	(count(*)::float)/(select count(*) from sales.customers) as "leads (%)"
from sales.customers
group by professional_status
order by "leads (%)"


-- (Query 3) Faixa etária dos leads
-- Colunas: faixa etária, leads (%)

create function datediff(unidade varchar, data_inicial date, data_final date)
returns integer
language sql

as

$$
	select
		case
			when unidade in ('d', 'day', 'days') then (data_final - data_inicial)
			when unidade in ('w', 'week', 'weeks') then (data_final - data_inicial)/7
			when unidade in ('m', 'month', 'months') then (data_final - data_inicial)/30
			when unidade in ('y', 'year', 'years') then (data_final - data_inicial)/365
$$
	
select
	case
		when datediff('y', birth_date, current_date) < 20 then '0-20'
		when datediff('y', birth_date, current_date) < 40 then '20-40'
		when datediff('y', birth_date, current_date) < 60 then '40-60'
		when datediff('y', birth_date, current_date) < 80 then '60-80'
		else '80+'
		end as "faixa etaria",
	count(*)::float/(select count(*) from sales.customers) as "leads (%)"
from sales.customers
group by "faixa etaria"
order by "faixa etaria" desc

-- (Query 4) Faixa salarial dos leads
-- Colunas: faixa salarial, leads (%), ordem

select	
	case
		when income < 5000 then '0-5000'
		when income < 10000 then '5000-10000'
		when income < 15000 then '10000-15000'
		when income < 20000 then '15000-20000'
		when income >= 20000 then '20000+'
		end as "faixa salarial",
	(count(*)::float/(select count(*) from sales.customers)) as "leads (%)",
	case
		when income < 5000 then 1
		when income < 10000 then 2
		when income < 15000 then 3
		when income < 20000 then 4
		when income >= 20000 then 5
		end as "ordem"
from sales.customers
group by "faixa salarial", "ordem"
order by "ordem"

-- (Query 5) Classificação dos veículos visitados
-- Colunas: classificação do veículo, veículos visitados (#)
-- Regra de negócio: Veículos novos tem até 2 anos e seminovos acima de 2 anos

with
	classificacao_idade as (
		select
			fun.visit_page_date,
			pro.model_year,
			extract('year' from visit_page_date) - pro.model_year::int as "age",
			case
				when (extract('year' from visit_page_date) - pro.model_year::int) <= 2 then 'novo'
				else 'seminovo'
				end as "classificacao"
		from sales.funnel as fun
		left join sales.products as pro
			on fun.product_id = pro.product_id
	)
select
	classificacao as "classificação do veículo",
	count(*) as "veículos visitados (#)"
from classificacao_idade
group by classificacao

	
select
	case
		when (select extract('y' from visit_page_date)) - pro.model_year::float <= 2 then 'novo'
		when (select extract('y' from visit_page_date)) - pro.model_year::float > 2 then 'seminovo'
		end as "classificacao do veiculo",
	 count(fun.visit_page_date) as "veiculos visitados (#)"
from sales.funnel as fun
left join sales.products as pro
	on fun.product_id = pro.product_id
group by "classificacao do veiculo"

	
-- (Query 6) Idade dos veículos visitados
-- Colunas: Idade do veículo (faixa de idade), veículos visitados (%), ordem

with
	tabela_faixa_idade_visitados as (
		select
			fun.visit_page_date,
			pro.model_year,
			extract('year' from visit_page_date) - pro.model_year::int as "age",
			case
				when extract('y' from visit_page_date) - model_year::int <= 2 then 'ate 2 anos'
				when extract('y' from visit_page_date) - model_year::int <= 4 then '2-4 anos'
				when extract('y' from visit_page_date) - model_year::int <= 6 then '4-6 anos'
				when extract('y' from visit_page_date) - model_year::int <= 8 then '6-8 anos'
				when extract('y' from visit_page_date) - model_year::int <= 10 then '8-10 anos'
				else '10+ anos'
				end as faixa_idade,
			case
				when extract('y' from visit_page_date) - model_year::int <= 2 then 1
				when extract('y' from visit_page_date) - model_year::int <= 4 then 2
				when extract('y' from visit_page_date) - model_year::int <= 6 then 3
				when extract('y' from visit_page_date) - model_year::int <= 8 then 4
				when extract('y' from visit_page_date) - model_year::int <= 10 then 5
				else 6
				end as ordem				
		from sales.funnel as fun
		left join sales.products as pro
			on fun.product_id = pro.product_id
	)
select
	faixa_idade as "faixa de idade",
	count(*)::float / (select count(*) from sales.funnel) as "veículos visitados (#)",
	ordem
from tabela_faixa_idade_visitados
group by faixa_idade, ordem
order by ordem


-- (Query 7) Veículos mais visitados por marca
-- Colunas: brand, model, visitas (#)

select
	pro.brand,
	pro.model,
	count(visit_page_date) as "visitas (#)"
from sales.products as pro
left join sales.funnel as fun
	on pro.product_id = fun.product_id
group by pro.model, pro.brand
order by pro.brand, pro.model









