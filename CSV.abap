*&---------------------------------------------------------------------*
*& Form create_csv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_csv.

  "Datendeklaration
  DATA:
    lt_output TYPE TABLE OF ty_alv WITH HEADER LINE,
    lt_iout   TYPE TABLE OF string,
    lv_xout   TYPE c LENGTH 4096,
    lv_file   LIKE tstrf01-file,
    lo_salv   TYPE REF TO cl_salv_table,
    ls_header TYPE string.
*===================================================================

  TRY.
      cl_salv_table=>factory(
          IMPORTING r_salv_table   = lo_salv
           CHANGING t_table        = gt_alv ).
    CATCH cx_salv_msg.
  ENDTRY.

  "Genereller Aufbau des Feldkatalogs
  DATA(lt_fcat) = cl_salv_controller_metadata=>get_lvc_fieldcatalog(
                   r_columns      = lo_salv->get_columns( )
                   r_aggregations = lo_salv->get_aggregations( ) ).

  "Ändere alle Spaltennamen
  LOOP AT lt_fcat ASSIGNING FIELD-SYMBOL(<fs_fcat>).
    <fs_fcat>-reptext = SWITCH #( <fs_fcat>-fieldname
                                  WHEN 'CHARG' THEN 'Charge'
                                  WHEN 'CERTN' THEN 'CERT-Nummer'
                                  WHEN 'LICHN' THEN 'Lieferantencharge'
                                  WHEN 'MATNR' THEN 'Produkt'
                                  WHEN 'MAKTX' THEN 'Bezeichnung'
                                  WHEN 'ALPHA' THEN'Alphawert'
                                  WHEN 'ANDAT' THEN 'Analysedatum'
                                  WHEN 'ANMET' THEN 'Analysemethode'
                                  WHEN 'SORTE' THEN 'Hopfensorte'
                                  WHEN 'ANBAU' THEN 'Anbaugebiet'
                                  WHEN 'ERNTJ' THEN 'Jahr'
                                  WHEN 'ERBAL' THEN 'Erste Ballennummer'
                                  WHEN 'LEBAL' THEN 'Letzte Ballennummer'
                                  WHEN 'WASWE' THEN 'Wasserwert [%]'
                                  WHEN 'NIOWW' THEN 'Wasserwert [%] NIO'
                                  WHEN 'NIOBA' THEN 'Anzahl NIO Ballen'
                                  WHEN 'IOBAL' THEN 'Anzahl IO Ballen'
                                  WHEN 'ANBAL' THEN 'Anzahl Ballen'
                                  WHEN 'LGTYP' THEN 'Lagertyp'
                                  WHEN 'LGPLA' THEN 'Lagerplatz'
                                  WHEN 'LGBER' THEN 'Lagerbereich'
                                  WHEN 'LOGPOS' THEN 'logische Position'
                                  WHEN 'VANRK' THEN 'VA-Nummer Kunde'
                                  WHEN 'BERDAT' THEN 'Bereitstellungsdatum'
                                  WHEN 'UMLDAT' THEN 'Datum letzte Umlagerung'
                                  WHEN 'ERDAT' THEN 'Angelegt am'
                                  WHEN 'AULAG' THEN 'Außenlager'
                                  WHEN 'BAULA' THEN 'Bezeichnung Außenlager'
                                  WHEN 'SPEDI' THEN 'Spediteur'
                                  WHEN 'BSPED' THEN 'Bezeichnung Spediteur'
                                  WHEN 'NTGEW' THEN 'Nettogewicht'
                                  WHEN 'GEWEI' THEN 'Gewichtseinheit'
                                  WHEN 'NOTIZ' THEN 'Bemerkung'
                                  WHEN 'WEDAT' THEN'Wareneingangsdatum der Charge'
                                  WHEN 'ANWEB' THEN 'Anzahl WE gebuchter Ballen' ).
  ENDLOOP.

  "Konstruiere Spaltenheader
  LOOP AT lt_fcat ASSIGNING FIELD-SYMBOL(<fs_t_columns>).
    "Hänge Spalte an String an
    ls_header = ls_header && <fs_t_columns>-reptext && |;|.
  ENDLOOP.

  "Zeilenumbruch
  ls_header = ls_header && |\n\r|.

  "Übergebe Header an CSV Tabelle
  APPEND ls_header TO lt_iout.

*-------------------------------------------------------------------
  "Übergabe aller Daten
  APPEND LINES OF gt_alv TO lt_output.

  "Lese Tabelle aus & konvertiere dies in einem String
  DATA(o_conv) = cl_rsda_csv_converter=>create( i_separator = ';' ).
  LOOP AT lt_output ASSIGNING FIELD-SYMBOL(<fs_output>).

    o_conv->structure_to_csv( EXPORTING
                                i_s_data = <fs_output>
                              IMPORTING
                                e_data = lv_xout ).
    "Entferne bei leeren Daten alle Platzhalter
    DATA(lv_cout) = replace( val = lv_xout sub = '" "' with = '' occ = 0 ).

    "Zeilenumbruch
    lv_cout = lv_cout && |\n\r|.

    "Übergabe an CSV Tabelle
    APPEND lv_cout TO lt_iout.
  ENDLOOP.

*-------------------------------------------------------------------
  "Output auf dem Applikationsserver
  IF lt_iout IS NOT INITIAL.
    DATA(lv_path) = |/transfer/HES/delivery/|.
    lv_file = lv_path && 'Bestandsinformation_Rohhopfenballen' && '_' && sy-datum && '.csv'.
    OPEN DATASET lv_file FOR OUTPUT IN TEXT MODE ENCODING UTF-8.
    LOOP AT lt_iout ASSIGNING FIELD-SYMBOL(<fs>).
      TRANSFER <fs> TO lv_file.
    ENDLOOP.
    CLOSE DATASET lv_file.
  ENDIF.
ENDFORM.
