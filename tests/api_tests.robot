*** Settings ***
Library    RequestsLibrary 

*** Test Cases ***
Varauksen luonti
    ${varaus_päivät}    Create Dictionary  checkin=2025-01-01  checkout=2025-01-04
    ${body}    Create Dictionary  firstname=Teppo  lastname=Testaaja  totalprice=${350}  
    ...    depositpaid=${True}  bookingdates=${varaus_päivät}  additionalneeds=Aamupala
    ${vastaus}    POST  https://restful-booker.herokuapp.com/booking  json=${body}  expected_status=200
    Should Contain    ${vastaus.json()}    bookingid
    Tarkista json    ${vastaus.json()}[booking]    ${body}

Varauksen luonti puuttuvilla kentillä
    ${varaus_päivät}    Create Dictionary  checkin=2025-01-01  checkout=2025-01-04
    ${body}    Create Dictionary  firstname=Teppo  depositpaid=${True}  bookingdates=${varaus_päivät} 
    ${vastaus}    POST  https://restful-booker.herokuapp.com/booking  json=${body}  expected_status=500
    Should Be Equal    ${vastaus.text}    Internal Server Error

Varauksen päivitys
    ${id}    Luo varaus ja palauta id
    ${token}    Luo ja palauta autentikointi token
    ${header}    Create Dictionary    Cookie=token\=${token}
    ${varaus_päivät}    Create Dictionary  checkin=2025-02-10  checkout=2025-02-12
    ${body}    Create Dictionary  firstname=Vallu  lastname=Varaaja  totalprice=${200}  
    ...    depositpaid=${True}  bookingdates=${varaus_päivät}  additionalneeds=Aamupala
    ${vastaus}    PUT  https://restful-booker.herokuapp.com/booking/${id}  json=${body} 
    ...    expected_status=200  headers=${header}
    Tarkista json    ${vastaus.json()}    ${body}

Varauksen päivitys ilman tunnistautumista
    ${id}    Luo varaus ja palauta id
    ${varaus_päivät}    Create Dictionary  checkin=2025-02-10  checkout=2025-02-12
    ${body}    Create Dictionary  firstname=Vallu  lastname=Varaaja  totalprice=${200}  
    ...    depositpaid=${True}  bookingdates=${varaus_päivät}  additionalneeds=Aamupala
    ${vastaus}    PUT  https://restful-booker.herokuapp.com/booking/${id}  json=${body}  expected_status=403
    Should Be Equal    ${vastaus.text}    Forbidden

Varauksen haku
    ${id}    Luo varaus ja palauta id
    @{vaaditut_kentät}    Create List  firstname  lastname  totalprice  depositpaid  
    ...    bookingdates  additionalneeds
    ${vastaus}    GET  https://restful-booker.herokuapp.com/booking/${id}  expected_status=200
    FOR    ${kenttä}    IN   @{vaaditut_kentät}
        Should Contain    ${vastaus.json()}    ${kenttä}
    END
    
Varauksen haku tuntemattomalla id:llä
    ${id}    Set Variable    500000
    ${vastaus}    GET  https://restful-booker.herokuapp.com/booking/${id}  expected_status=404
    Should Be Equal    ${vastaus.text}    Not Found

Varauksen poisto
    ${id}    Luo varaus ja palauta id
    ${token}    Luo ja palauta autentikointi token
    ${header}    Create Dictionary    Cookie=token\=${token}
    ${vastaus}    DELETE  https://restful-booker.herokuapp.com/booking/${id}  
    ...    expected_status=201  headers=${header}
    ${vastaus_body}    Set Variable    ${vastaus.text}
    Should Be Equal    ${vastaus_body}    Created
    ${vastaus}    GET  https://restful-booker.herokuapp.com/booking/${id}  expected_status=404
    Should Be Equal    ${vastaus.text}    Not Found

Varauksen poisto tuntemattomalla id:llä
    ${id}    Set Variable    500000
    ${token}    Luo ja palauta autentikointi token
    ${header}    Create Dictionary    Cookie=token\=${token}
    ${vastaus}    DELETE  https://restful-booker.herokuapp.com/booking/${id}  
    ...    expected_status=405  headers=${header}
    Should Be Equal    ${vastaus.text}    Method Not Allowed

*** Keywords ***
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
    Should Be Equal As Integers    ${vastaus_json}[totalprice]    ${odotettu_json}[totalprice]
    Should Be Equal    ${vastaus_json}[bookingdates]    ${odotettu_json}[bookingdates]