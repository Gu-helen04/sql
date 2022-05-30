--***********************Итоговая работа***************************
--***********************  1   ************************************

with cte1 as ( 
				select city ,count(airport_name)  as num_airport
				from airports a 
				group by city
				)
select  city
from  cte1 
where num_airport > 1
order by num_airport


--***********************  2   ************************************

select DISTINCT departure_airport_name 
from flights_v fv 
where aircraft_code  = (	
							select aircraft_code
							from aircrafts_data ad
							order by "range" desc limit 1 )
							
							
--***********************  3   ************************************

with cte1 as ( select *  --EXTRACT(EPOCH FROM (TIMESTAMP actual_departure - TIMESTAMP scheduled_departure)) as flight_delay  
from flights f 
where actual_departure is not null 
)
select *, EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) as flight_delay
from cte1 
order by flight_delay desc limit 10




--***********************  4   ************************************ 

select 
	case when count(b.book_ref) > 0 then 'Да'
	else 'Нет'
	end have_armor,
	count(b.book_ref) amount
from bookings b 
join tickets t on t.book_ref = b.book_ref 
left join boarding_passes bp on bp.ticket_no = t.ticket_no 
where bp.boarding_no is null



--***********************  5   ************************************

with cte1 as (select f.flight_id,f.flight_no,f.aircraft_code,f.departure_airport,f.scheduled_departure,f.actual_departure,count(bp.boarding_no) as boarded_count
				 from flights f 
	             join boarding_passes bp on bp.flight_id = f.flight_id 
	             where f.actual_departure is not null
	             group by f.flight_id ),
	  cte2 as(select s.aircraft_code,count(s.seat_no) as max_seats
		   	  from seats s 
	          group by s.aircraft_code)
select c1.flight_no, c1.departure_airport, c1.scheduled_departure, c1.actual_departure, c1.boarded_count,
	c2.max_seats - c1.boarded_count free_seats, 
	round((c2.max_seats - c1.boarded_count) / c2.max_seats :: dec, 2) * 100 free_seats_percent,
	sum(c1.boarded_count) over (partition by (c1.departure_airport, c1.actual_departure::date)
order by c1.actual_departure) as sum_
from cte1 c1 
join cte2 c2 on c2.aircraft_code = c1.aircraft_code



--***********************  6   ************************************
with cte1 as( select  count(f.flight_no) as all_flight_air, ad.model as model
			  from flights f
			  LEFT outer join aircrafts ad on f.aircraft_code = ad.aircraft_code 
	          group by ad.model ),
	 cte2 as(select model,all_flight_air, SUM(all_flight_air) OVER() AS SUM_
			  from cte1)
select model, all_flight_air , round((all_flight_air * 100.0 / SUM_),2) as procent_fl
from cte2 

--***********************  7   ************************************

with cte1 as (select fv.flight_no as flight_no_ec,  count(tf.ticket_no) ,tf.fare_conditions as fare_conditions_ec,tf.amount as amount_ec, fv.arrival_city as arrival_city_ec 
	          from flights_v fv 
              LEFT OUTER join ticket_flights tf on fv.flight_id = tf.flight_id 
              where tf.fare_conditions  = 'Economy'
              group by  flight_no_ec, fare_conditions_ec, amount_ec,arrival_city_ec ), 
	cte2 as (select fv.flight_no as flight_no_bis,  count(tf.ticket_no) ,tf.fare_conditions as fare_conditions_bis,tf.amount as amount_bis,fv.arrival_city  as arrival_city_bis  
             from flights_v fv 
             LEFT OUTER join ticket_flights tf on fv.flight_id = tf.flight_id 
             where tf.fare_conditions = 'Business'
             group by  flight_no_bis, fare_conditions_bis, amount_bis, arrival_city_bis  )   
select arrival_city_ec , amount_ec,amount_bis  
from cte1 
join cte2 on flight_no_ec = flight_no_bis 
where amount_bis < amount_ec 
 
--***********************  8   ************************************


select distinct  a.city,a2.city 
from airports a, airports a2
where a.city <>a2.city 
except select fv.departure_city ,fv.arrival_city 
from flights_v fv

--***********************  9   ************************************

select distinct a1.airport_name as dispatch_city_, a2.city as arrival_city_, ad."range" as aircraft_range_,
round((acos(sind(a1.coordinates[0]) * sind(a2.coordinates[0]) + cosd(a1.coordinates[0]) * cosd(a2.coordinates[0]) * cosd(a1.coordinates[1] - a2.coordinates[1])) * 6371)::dec, 2) as between_cities,		
case when 
	ad."range" <
	acos(sind(a1.coordinates[0]) * sind(a2.coordinates[0]) + cosd(a1.coordinates[0]) * cosd(a2.coordinates[0]) * cosd(a1.coordinates[1] - a2.coordinates[1])) * 6371 
	then 'Не долетит'
	else 'Долетит'
	end resuilt
from flights f
join airports a1 on f.departure_airport = a1.airport_code
join airports  a2 on f.arrival_airport = a2.airport_code
join aircrafts_data ad on ad.aircraft_code = f.aircraft_code 