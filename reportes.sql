--Reporte 1: Total de descarga por Ha en litros por hectárea: descargasHa
CREATE OR REPLACE FUNCTION public.reporte1(configID int, droneID int) RETURNS double precision AS $$
DECLARE 
	duracion double precision;
	volumen double precision;
BEGIN
	SELECT configuraciones.volumen_descarga INTO STRICT volumen FROM public.configuraciones WHERE configuraciones.id = configID AND drone = droneID;
	SELECT drones.duracion_bateria INTO STRICT duracion FROM public.drones WHERE drones.id = droneID;
	RETURN duracion * volumen;
END;
$$ LANGUAGE plpgsql;

--Reporte 2: Total de llenadas de tanque por hectárea: llenadasTanqueHa
CREATE OR REPLACE FUNCTION public.reporte2(descargasHa double precision, areaTotal double precision, droneID int) RETURNS double precision AS $$
DECLARE
	capacidad double precision;
BEGIN
	SELECT drones.capacidad_tanque INTO STRICT capacidad FROM public.drones WHERE drones.id = droneID;
	RETURN descargasHa * areaTotal / capacidad;
END;
$$ LANGUAGE plpgsql;

--Reporte 3: Total litros a descargar por área total en litros: litrosAreaTot
CREATE OR REPLACE FUNCTION public.reporte3(descargasHa double precision, areaTotal double precision) RETURNS double precision AS $$
BEGIN
	RETURN descargasHa * areaTotal;
END;
$$ LANGUAGE plpgsql;

--Reporte 4: Total de llenadas de tanque por área total: llenadasAreaTot
CREATE OR REPLACE FUNCTION public.reporte4(llenadasTanqueHa double precision, areaTotal double precision) RETURNS double precision AS $$
BEGIN
	RETURN llenadasTanqueHa * areaTotal;
END;
$$ LANGUAGE plpgsql;

--Reporte 5: Total de cada producto por Tanque en litros por tanque: totalProdsTanque
CREATE OR REPLACE FUNCTION public.reporte5(llenadasTanqueHa double precision, prodsIDS int[]) RETURNS double precision[] AS $$
DECLARE
	dosis double precision;
	totales double precision[];
	idProd int;
BEGIN
	FOREACH idProd IN ARRAY prodsIDS
	LOOP
		SELECT productos.dosis_media INTO STRICT dosis FROM public.productos WHERE productos.id = idProd;
		totales := array_append(totales, dosis / llenadasTanqueHa);
	END LOOP;
	RETURN totales;
END;
$$ LANGUAGE plpgsql;

--Reporte 6: Total de agua por tanque en litros por tanque: aguaTanque
CREATE OR REPLACE FUNCTION public.reporte6(droneID int, totalProdsTanque double precision[]) RETURNS double precision AS $$
DECLARE
	prodTanque double precision;
	sumaProds double precision;
	capacidadTanque double precision;
BEGIN
	sumaProds := 0;
	FOREACH prodTanque IN ARRAY totalProdsTanque
	LOOP
		sumaProds := sumaProds + prodTanque;
	END LOOP;
	SELECT drones.capacidad_tanque INTO STRICT capacidadTanque FROM public.drones WHERE drones.id = droneID;
	RETURN capacidadTanque - sumaProds;
END
$$ LANGUAGE plpgsql;

--Reporte 7: Total de cada Producto por hectárea en litros por hectárea: totalProdsHa
CREATE OR REPLACE FUNCTION public.reporte7(totalProdsTanque double precision[], llenadasTanqueHa double precision) RETURNS double precision[] AS $$
DECLARE 
	prodsHa double precision[];
	totProd double precision;
BEGIN
	FOREACH totProd IN ARRAY totalProdsTanque
	LOOP
		prodsHa := array_append(prodsHa, totProd * llenadasTanqueHa);
	END LOOP;
	RETURN prodsHa;
END $$ LANGUAGE plpgsql;
	
--Reporte 8: Total de Agua por hectárea en litros por hectárea: aguaHa
CREATE OR REPLACE FUNCTION public.reporte8(llenadasTanqueHa double precision, aguaTanque double precision) RETURNS double precision AS $$
BEGIN
	RETURN llenadasTanqueHa * aguaTanque;
END;
$$ LANGUAGE plpgsql;

--Reporte 9: Total de descarga  por hectárea en litros por hectárea
--Repetido del reporte 1

--Reporte 10: Total de cada Producto x área total en litros por total de total de hectáreas: totalProdsAreaTot
CREATE OR REPLACE FUNCTION public.reporte10(totalProdsHa double precision[], areaTotal double precision) RETURNS double precision[] AS $$
DECLARE
	prodHa double precision;
	prodsHaTot double precision[];
BEGIN
	FOREACH prodHa IN ARRAY totalProdsHa
	LOOP
		prodsHaTot := array_append(prodsHaTot, prodHa * areaTotal);
	END LOOP;
	RETURN prodsHaTot;
END $$ LANGUAGE plpgsql;

--Reporte 11: Total de Agua por área total en Litros por total de hectáreas: aguaAreaTot
CREATE OR REPLACE FUNCTION public.reporte11(aguaHa double precision, areaTotal double precision) RETURNS double precision AS $$
BEGIN
	RETURN aguaHa * areaTotal;
END $$ LANGUAGE plpgsql;

--Reporte 12: Total de descarga por área total en Litros por total de hectáreas: descargasAreaTot
CREATE OR REPLACE FUNCTION public.reporte12(descargasHa double precision, areaTotal double precision) RETURNS double precision AS $$
BEGIN
	RETURN descargasHa * areaTotal;
END $$ LANGUAGE plpgsql;

--Generacion de reportes y retorno
CREATE OR REPLACE FUNCTION public.generarReportes(configID int, droneID int, prodsIDS int[], areaTotal double precision) RETURNS table(
	descargasHa double precision,				--Reporte 1		configID, droneID
	llenadasTanqueHa double precision,			--Reporte 2		descargasHa, areaTotal, droneID
	litrosAreaTot double precision,				--Reporte 3		descargasHa, areaTotal
	llenadasAreaTot double precision,			--Reporte 4		llenadasTanqueHa, areaTotal
	totalProdsTanque double precision[],		--Reporte 5		llenadasTanqueHa, prodsIDS
	aguaTanque double precision,				--Reporte 6		droneID, totalProdsTanque
	totalProdsHa double precision[],			--Reporte 7		totalProdsTanque, llenadasTanqueHa
	aguaHa double precision,					--Reporte 8		llenadasTanqueHa, aguaTanque
	totalProdsAreaTot double precision[],		--Reporte 10	totalProdsHa, areaTotal
	aguaAreaTot double precision,				--Reporte 11	aguaHa, areaTotal
	descargasAreaTot double precision			--Reporte 12	descargasHa, areaTotal
) AS $$
BEGIN
	descargasHa := (SELECT * FROM public.reporte1(configID, droneID));						
	llenadasTanqueHa := (SELECT * FROM public.reporte2(descargasHa, areaTotal, droneID));
	litrosAreaTot := (SELECT * FROM public.reporte3(descargasHa, areaTotal));
	llenadasAreaTot := (SELECT * FROM public.reporte4(llenadasTanqueHa, areaTotal));
	totalProdsTanque := (SELECT * FROM public.reporte5(llenadasTanqueHa, prodsIDS));
	aguaTanque := (SELECT * FROM public.reporte6(droneID, totalProdsTanque));
	totalProdsHa := (SELECT * FROM public.reporte7(totalProdsTanque, llenadasTanqueHa));
	aguaHa := (SELECT * FROM public.reporte8(llenadasTanqueHa, aguaTanque));
	totalProdsAreaTot := (SELECT * FROM public.reporte10(totalProdsHa, areaTotal));
	aguaAreaTot := (SELECT * FROM public.reporte11(aguaHa, areaTotal));
	descargasAreaTot := (SELECT * FROM public.reporte12(descargasHa, areaTotal));
	
	RETURN NEXT;
END $$ LANGUAGE plpgsql;