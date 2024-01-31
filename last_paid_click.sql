-- формирование витрины по модели атрибуции Last Paid Click
with query_1 as (
	select
		visitor_id,
		max(visit_date) as visit_date,
		source as utm_source,
		medium as utm_medium,
		campaign as utm_campaign,
		content as utm_content
	from sessions
	where medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
	group by 
		visitor_id,
		utm_source,
		utm_medium,
		utm_campaign,
		utm_content
)
select
	query_1.visitor_id,
	to_char(query_1.visit_date, 'YYYY-MM-DD HH24:MI:SS.MS') as visit_date,
	query_1.utm_source,
	query_1.utm_medium,
	query_1.utm_campaign,
	leads.lead_id,
	to_char(leads.created_at, 'YYYY-MM-DD HH24:MI:SS.MS') as created_at,
	leads.amount,
	leads.closing_reason,
	leads.status_id
from query_1
left join leads
	on 
		query_1.visitor_id = leads.visitor_id 
		and query_1.visit_date >= leads.created_at
order by 
	amount desc nulls last,
	visit_date,
	utm_source,
	utm_medium,
	utm_campaign;

