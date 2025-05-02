*** Settings ***
Library    RequestsLibrary 
Variables    ../test_data/test_data.yaml

*** Test Cases ***
Varauksen luonti
    [Template]    Varauksen luonti
    ${varauksen_luonti_onnistuneesti}    ok
    ${varauksen_luonti_puuttuvilla_kentillä}    error

Varauksen päivitys
    [Template]    Varauksen päivitys
    ${varauksen_päivitys_onnistuneesti}    ok
    ${varauksen_päivitys_ilman_tunnistautumista}    forbidden

Varauksen haku
    [Template]    Varauksen haku
    ${varauksen_haku_onnistuneesti}    ok
    ${varauksen_haku_tuntemattomalla_tunnisteella}    notfound

Varauksen poisto
    [Template]    Varauksen poisto
    ${varauksen_poisto_onnistuneesti}
    ${varauksen_poisto_tuntemattomalla_tunnisteella}


*** Keywords ***
Varauksen luonti
    [Arguments]    ${testidata}    ${tapaus}
    ${vastaus}    POST  ${base_url}/booking  json=${testidata}[body]  
    ...    expected_status=${testidata}[odotettu_vastaus][tilakoodi]
    IF    "${tapaus}" == "ok"
        Should Contain    ${vastaus.json()}    bookingid
    ELSE
        Should Be Equal    ${vastaus.text}    ${testidata}[odotettu_vastaus][body]
    END

Varauksen päivitys
    [Arguments]    ${testidata}    ${tapaus}
    ${id}    Luo varaus ja palauta id
    ${header}    Create Dictionary    Cookie=
    IF    ${testidata}[käytä_todennusta]
        ${token}    Luo ja palauta autentikointi token
        ${header}[Cookie]    Set Variable   token\=${token}
    END
    ${vastaus}    PUT  ${base_url}/booking/${id}  json=${testidata}[body]
    ...    expected_status=${testidata}[odotettu_vastaus][tilakoodi]  headers=${header}
    IF    "${tapaus}" == "ok"
        Tarkista json    ${vastaus.json()}    ${testidata}[odotettu_vastaus][body]
    ELSE
        Should Be Equal    ${vastaus.reason}    ${testidata}[odotettu_vastaus][body]
    END

Varauksen haku
    [Arguments]    ${testidata}    ${tapaus}
    IF    ${testidata}[luo_varaus]
        ${id}    Luo varaus ja palauta id
    ELSE
        ${id}    Set Variable    500000 
    END
    ${vastaus}    GET  ${base_url}/booking/${id}  
    ...    expected_status=${testidata}[odotettu_vastaus][tilakoodi]
    IF    "${tapaus}" == "ok"
        FOR    ${kenttä}    IN   @{testidata}[odotettu_vastaus][vaaditut_kentät]
            Should Contain    ${vastaus.json()}    ${kenttä}
        END
    ELSE
        Should Be Equal    ${vastaus.reason}    ${testidata}[odotettu_vastaus][body]
    END

Varauksen poisto
    [Arguments]    ${testidata}
    IF    ${testidata}[luo_varaus]
        ${id}    Luo varaus ja palauta id
    ELSE
        ${id}    Set Variable    500000 
    END
    ${token}    Luo ja palauta autentikointi token
    ${header}    Create Dictionary    Cookie=token\=${token}
    ${vastaus}    DELETE  ${base_url}/booking/${id}  
    ...    expected_status=${testidata}[DELETE][odotettu_vastaus][tilakoodi]  headers=${header}
    Should Be Equal    ${vastaus.text}    ${testidata}[DELETE][odotettu_vastaus][body]
    ${vastaus}    GET  ${base_url}/booking/${id}  
    ...    expected_status=${testidata}[GET][odotettu_vastaus][tilakoodi]
    Should Be Equal    ${vastaus.text}    ${testidata}[GET][odotettu_vastaus][body]

Luo varaus ja palauta id
    ${varaus_päivät}    Create Dictionary  checkin=2025-01-01  checkout=2025-01-04
    ${body}    Create Dictionary  firstname=Teppo  lastname=Testaaja  totalprice=${350}  
    ...    depositpaid=${True}  bookingdates=${varaus_päivät}  additionalneeds=Aamupala
    ${vastaus}    POST  https://restful-booker.herokuapp.com/booking  json=${body}  expected_status=200
    ${vastaus_body}    Set Variable    ${vastaus.json()}
    RETURN    ${vastaus_body}[bookingid]

Luo ja palauta autentikointi token
    ${body}    Create Dictionary  username=admin  password=password123
    ${vastaus}    POST  https://restful-booker.herokuapp.com/auth  json=${body}
    RETURN    ${vastaus.json()}[token]

Tarkista json
    [Arguments]    ${vastaus_json}  ${odotettu_json}
    Should Be Equal    ${vastaus_json}[firstname]    ${odotettu_json}[firstname]
    Should Be Equal    ${vastaus_json}[lastname]    ${odotettu_json}[lastname]
    Should Be Equal    ${vastaus_json}[depositpaid]    ${odotettu_json}[depositpaid]
    Should Be Equal As Integers    ${vastaus_json}[totalprice]    ${odotettu_json}[totalprice]
    Should Be Equal    ${vastaus_json}[bookingdates]    ${odotettu_json}[bookingdates]