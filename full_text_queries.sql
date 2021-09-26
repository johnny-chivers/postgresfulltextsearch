-------------
-- Query 1 --
-------------
SELECT 
		firstname
		,middlename
		,lastname
FROM
		customer
WHERE 
		to_tsvector(firstname||' '||middlename||' '||lastname) @@ to_tsquery('Gee'); 
		
		
---------------------------------------
-- Look at what to_tsvector is doing --
---------------------------------------
SELECT 
		firstname
		,middlename
		,lastname
		,to_tsvector(firstname||' '||middlename||' '||lastname)
FROM
		customer; 
	
	
	
SELECT to_tsvector('YouTube is the best place online for AWS. AWS tutorials are great on YouTube'); 


--------------------------------------------------
-- Create Persisted Column To speed up queries  --
--------------------------------------------------
ALTER TABLE customer
	ADD COLUMN full_name tsvector;
UPDATE customer
	set full_name= to_tsvector(firstname||' '||middlename||' '||lastname);

SELECT 
	full_name
FROM 
	customer LIMIT 10; 
	
	
SELECT 
		firstname
		,middlename
		,lastname
FROM
		customer
WHERE 
		full_name @@ to_tsquery('Gee'); 
	
	
--------------------------------------------------
-- 	   Lets look at the execution plans  		--
--------------------------------------------------		
EXPLAIN ANALYSE SELECT  
						firstname
						,middlename
						,lastname
				FROM
						customer
				WHERE 
						to_tsvector(firstname||' '||middlename||' '||lastname) @@ to_tsquery('Gee'); 


						
EXPLAIN ANALYSE SELECT 
						firstname
						,middlename
						,lastname
				FROM
						customer
				WHERE 
						full_name @@ to_tsquery('Gee'); 
						
------------------------
-- Adding a GIN Index --
------------------------
ALTER TABLE customer 
	 ADD COLUMN full_name_index tsvector;
UPDATE customer
	set full_name_index = to_tsvector(firstname||' '||middlename||' '||lastname);
CREATE INDEX full_name_idx
	ON customer
	USING GIN(full_name_index); 
	
-------------------------
-- COMPARING GIN INDEX --
-------------------------

EXPLAIN ANALYSE SELECT 
						firstname
						,middlename
						,lastname
				FROM
						customer
				WHERE 
						full_name @@ to_tsquery('Gee'); 
						
						

EXPLAIN ANALYSE SELECT 
						firstname
						,middlename
						,lastname
				FROM
						customer
				WHERE 
						full_name_index @@ to_tsquery('Gee'); 
						
						
------------------------------
-- Partial string searching --
------------------------------
SELECT 
		firstname
		,middlename
		,lastname
FROM
		customer
WHERE 
		full_name_index @@ to_tsquery('Mar:*'); 

						
-----------------------
-- Ranking  Searches --
-----------------------
SELECT 
		firstname
		,middlename
		,lastname
		,ts_rank(full_name_index,to_tsquery('Mar:*'))  as rank
FROM
		customer
WHERE 
		full_name_index @@ to_tsquery('Mar:*')
ORDER BY 
		ts_rank(full_name_index,to_tsquery('Mar:*')) desc

----------------------------------------------
-- Ranking  Searches with Column weightings --
----------------------------------------------
ALTER TABLE customer
	ADD COLUMN full_name_with_weights tsvector;
UPDATE customer
SET full_name_with_weights = setweight(to_tsvector(firstname),'B') ||
							setweight(to_tsvector(middlename),'C') ||
							setweight(to_tsvector(lastname),'A'); 
CREATE INDEX full_name_with_weights_idx
	ON customer	
	USING GIN (full_name_with_weights);

--- query for rank 
SELECT 
		firstname
		,middlename
		,lastname
		,ts_rank(full_name_with_weights,to_tsquery('Mar:*'))  as rank
FROM
		customer
WHERE 
		full_name_with_weights @@ to_tsquery('Mar:*')
ORDER BY 
		ts_rank(full_name_with_weights,to_tsquery('Mar:*')) desc

