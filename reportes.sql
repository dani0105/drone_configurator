
--Reporte 1: Total de descarga por Ha en litros por hectárea
CREATE OR REPLACE FUNCTION public.reporte1(configID int, droneID int) RETURNS double precision AS $$
DECLARE 
	duracion double precision;
	volumen double precision;
BEGIN
	SELECT configuraciones.volumen_descarga INTO STRICT volumen FROM public.configuraciones WHERE id = configID AND drone = droneID;
	SELECT drones.duracion_bateria INTO STRICT duracion FROM public.drones WHERE id = droneID;
	RETURN duracion * volumen;
END;
$$ LANGUAGE plpgsql;

--Reporte 2: Total de llenadas de tanque por hectárea
CREATE OR REPLACE FUNCTION public.reporte2(descargas double precision, areaTotal double precision, droneID int) RETURNS double precision AS $$
DECLARE
	capacidad double precision;
BEGIN
	SELECT drones.capacidad_tanque INTO STRICT capacidad FROM public.drones WHERE id = droneID;
	RETURN descargas * areaTotal / capacidad;
END;
$$ LANGUAGE plpgsql;

--Reporte 3: Total litros a descargar por área total en litros
CREATE OR REPLACE FUNCTION public.reporte3(descarga double precision, areaTotal double precision) RETURNS double precision AS $$
BEGIN
	RETURN descarga * areaTotal;
END
$$ LANGUAGE plpgsql;

--Reporte 4: Total de llenadas de tanque por área total
CREATE OR REPLACE FUNCTION public.reporte4(llenadas double precision, areaTotal double precision) RETURNS double precision AS $$
BEGIN
	RETURN llenadas * areaTotal;
END
$$ LANGUAGE plpgsql;

--Reporte 5: Total de cada producto por Tanque en litros por tanque
CREATE OR REPLACE FUNCTION public.reporte5(llenadas double precision, productosIDS int[]) RETURNS double precision[] AS $$
DECLARE
	dosis double precision;
	totales double precision[];
BEGIN
	FOREACH idProd SLICE 1 IN ARRAY productosIDS
	LOOP
		SELECT productos.dosis_media INTO STRICT dosis FROM productos WHERE id = idProd;
		totales := array_append(totales, dosis * llenadas);
	END LOOP
	RETURN totales;
END
$$ LANGUAGE plpgsql;

--Reporte 6: Total de agua por tanque en litros por tanque
CREATE OR REPLACE FUNCTION public.reporte6(descargas double precision, sumDosis double precision) RETURNS double precision AS $$
BEGIN
	RETURN descargas - sumDosis;
END
$$ LANGUAGE plpgsql;		