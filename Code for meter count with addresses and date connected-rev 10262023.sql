---------------------------------------------------------------------
-- Teo Espero
-- IT Administrator
-- Marina Coast Water District (MCWD)
-- 10/05/2022
-- this code is used for providing a count of active connections 
-- for a specific period
---------------------------------------------------------------------

---------------------------------------------------------------------
-- :: STEP 01
-- :: Define the period that you require, and gather unique reads 
-- :: during that period.
select 
	distinct
	reading_period,
	cust_no,
	cust_sequence
	into #meters_read
from ub_meter_hist
where
	reading_year = 2023
	and reading_period = 9
order by
	reading_period

-- select * from #meters_read


---------------------------------------------------------------------
-- :: STEP 02
-- :: Define the period that you require
-- :: Cross-reference the read's acct info with that of
-- :: the Lot Nos
select 
	distinct
	mr.reading_period,
	m.lot_no
	into #lots_read
from ub_master m
inner join
	#meters_read mr
	on mr.cust_no=m.cust_no
	and mr.cust_sequence=m.cust_sequence
order by
	mr.reading_period

-- select * from #lots_read

---------------------------------------------------------------------
-- :: STEP 03
-- :: create rows that have the counts

--:: Non-Bay View
select 
	lr.reading_period,
	l.misc_2 as ST_Category,
	l.misc_1 as Boundary,
	l.misc_5 as Subdivision,
	l.misc_16 as Irrigation,
	l.misc_17  as IrrType,
	l.street_number,
	l.street_name,
	l.city,
	1 as ActiveMtrCount,
	l.lot_no
	into #themetercount01
from lot l
inner join
	#lots_read lr
	on lr.lot_no=l.lot_no
	and misc_5 != 'Bay View'
order by
	lr.reading_period,
	l.misc_2 

--:: Bay View Master Account
insert into #themetercount01
(
	reading_period,
	ST_Category,
	Boundary,
	Subdivision,
	Irrigation,
	IrrType,
	street_number,
	street_name,
	city,
	ActiveMtrCount,
	lot_no
)
select 
	lr.reading_period,
	l.misc_2 as ST_Category,
	l.misc_1 as Boundary,
	l.misc_5 as Subdivision,
	l.misc_16 as Irrigation,
	l.misc_17 as IrrType,
	l.street_number,
	l.street_name,
	l.city,
	1 as ActiveMtrCount,
	l.lot_no
from lot l
inner join
	#lots_read lr
	on lr.lot_no=l.lot_no
	and misc_5 = 'Bay View'
	and l.lot_no=990
order by
	lr.reading_period,
	l.misc_2

select 
	mc.reading_period,
	mc.ST_Category,
	mc.Boundary,
	mc.Subdivision,
	mc.Irrigation,
	mc.IrrType,
	mc.street_number,
	mc.street_name,
	mc.city,
	mc.ActiveMtrCount,
	mc.lot_no,
	m.connect_date
	into #metercount02
from #themetercount01 mc
inner join
	ub_master m
	on m.lot_no=mc.lot_no


select 
	distinct
	t.reading_period,
	t.ST_Category,
	t.Boundary,
	t.Subdivision,
	t.Irrigation,
	t.IrrType,
	t.street_number,
	t.street_name,
	t.city,
	t.ActiveMtrCount,
	t.lot_no,
	t.connect_date
	--into #unique_lots
from #metercount02 t
inner join (
	select lot_no, 
	min(connect_date) as MinDate
    from #metercount02
    group by lot_no
) tm 
on 
	t.lot_no = tm.lot_no
	and t.connect_date=tm.MinDate
order by
	t.lot_no


--:: Clean up
drop table #lots_read
drop table #meters_read
drop table #themetercount01

---------------------------------------------------------------------