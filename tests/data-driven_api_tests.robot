*** Settings ***
Library    RequestsLibrary 
Variables    ../test_data/test_data.yml

*** Test Cases ***
Varauksen luonti
    [Template]    Varauksen luonti
    ${testitapaus_1}
    ${testitapaus_2}

# Varauksen luonti
#     ${vastaus}    POST  ${base_url}/booking  json=${testitapaus_1}[body]  expected_status=${testitapaus_1}[odotettu_tilakoodi]
#     ${vastaus_body}    Set Variable    ${vastaus.json()}
#     Should Contain    ${vastaus_body}    bookingid
#     Tarkista vastauksen body    ${vastaus_body}[booking]    ${testitapaus_1}[body]

Varauksen luonti puuttuvilla kentillä
    ${vastaus}    POST  ${base_url}/booking  json=${testitapaus_2}[body]  expected_status=${testitapaus_2}[odotettu_tilakoodi]
    Should Be Equal    ${vastaus.text}    ${testitapaus_2}[odotettu_vastaus]

Varauksen päivitys
    ${id}    Luo varaus ja palauta id
    ${token}    Luo ja palauta autentikointi token
    ${header}    Create Dictionary    Cookie=token\=${token}
    ${vastaus}    PUT  ${base_url}/booking/${id}  json=${testitapaus_3}[body]
    ...    expected_status=${testitapaus_3}[odotettu_tilakoodi]  headers=${header}
    Tarkista vastauksen body    ${vastaus.json()}    ${testitapaus_3}[body]

Varauksen päivitys ilman tunnistautumista
    ${id}    Luo varaus ja palauta id
    ${vastaus}    PUT  ${base_url}/booking/${id}  json=${testitapaus_4}[body]
    ...    expected_status=${testitapaus_4}[odotettu_tilakoodi]
    Should Be Equal    ${vastaus.text}    ${testitapaus_4}[odotettu_vastaus]

Varauksen haku
    ${id}    Luo varaus ja palauta id
    ${vastaus}    GET  ${base_url}/booking/${id}  expected_status=${testitapaus_5}[odotettu_tilakoodi]
    FOR    ${kenttä}    IN   @{testitapaus_5}[vaaditut_kentät]
        Should Contain    ${vastaus.json()}    ${kenttä}
    END
    
Varauksen haku tuntemattomalla id:llä
    ${id}    Set Variable    500000
    ${vastaus}    GET  ${base_url}/booking/${id}  expected_status=${testitapaus_6}[odotettu_tilakoodi]
    Should Be Equal    ${vastaus.text}    ${testitapaus_6}[odotettu_vastaus]

Varauksen poisto
    ${id}    Luo varaus ja palauta id
    ${token}    Luo ja palauta autentikointi token
    ${header}    Create Dictionary    Cookie=token\=${token}
    ${vastaus}    DELETE  ${base_url}/booking/${id}  
    ...    expected_status=${testitapaus_7}[odotettu_tilakoodi]  headers=${header}
    Should Be Equal    ${vastaus.text}    ${testitapaus_7}[odotettu_vastaus]
    ${vastaus}    GET  ${base_url}/booking/${id}  expected_status=404
    Should Be Equal    ${vastaus.text}    Not Found

Varauksen poisto tuntemattomalla id:llä
    ${id}    Set Variable    500000
    ${token}    Luo ja palauta autentikointi token
    ${header}    Create Dictionary    Cookie=token\=${token}
    ${vastaus}    DELETE  ${base_url}/booking/${id}  
    ...    expected_status=${testitapaus_8}[odotettu_tilakoodi]  headers=${header}
    Should Be Equal    ${vastaus.text}    Method Not Allowed

*** Keywords ***
Varauksen luonti
    [Arguments]    ${testi_data}
    ${vastaus}    POST  ${base_url}/booking  json=${testi_data}[body]  expected_status=${testi_data}[odotettu_tilakoodi]
    Tarkista vastaus    ${vastaus}    ${testi_data}

Tarkista vastaus
    [Arguments]    ${vastaus}    ${testi_data}
    TRY
        Should Contain    ${vastaus.json()}    bookingid
    EXCEPT
        Should Be Equal    ${vastaus.text}    ${testi_data}[odotettu_vastaus]
    END


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

Tarkista vastauksen body
    [Arguments]    ${vastaus_body}  ${odotettu_body}
    Should Be Equal    ${vastaus_body}[firstname]    ${odotettu_body}[firstname]
    Should Be Equal    ${vastaus_body}[lastname]    ${odotettu_body}[lastname]
    Should Be Equal As Integers    ${vastaus_body}[totalprice]    ${odotettu_body}[totalprice]
    Should Be Equal    ${vastaus_body}[bookingdates]    ${odotettu_body}[bookingdates]