---
---
class @Votes2015
  constructor: (@rawData, @data, @districtNames) ->

  setDistrictNames: (districtNames) ->
    @districtNames = districtNames

  setResultsPerDistrict: (perDistrict) ->
    @resultsPerDistrict = perDistrict

  formatForDistricts: ->
    districtStartPosition = 0
    for districtName in @districtNames
      districtNumber = @districtNumberForName(districtName)
      rawResult = @rawForDistrict(districtStartPosition)
      @addRawForDistrict(rawResult, districtNumber)
      districtStartPosition += @resultsPerDistrict
    @formatResults()

  formatForSubDistricts: ->
    districtStartPosition = 0
    @data = for districtName in @districtNames
      districtNumber = parseInt(@subDistrictNumberForName(districtName))
      rawResult = @rawForDistrict(districtStartPosition)
      districtStartPosition += @resultsPerDistrict
      { "wahlbezirk_nr": districtNumber, "result": rawResult }
    @formatResults()

  subDistrictNumberForName: (name) ->
    bezirkArr = name.match(/^[0-9]{3}/)
    if bezirkArr && bezirkArr.length > 0
      bezirkArr[0]

  districtNumberForName: (name) ->
    bezirkArr = name.match(/^[0-9]{2}/)
    if(bezirkArr && bezirkArr.length > 0)
      bezirkArr[0]
    else
      briefArr = name.match(/^[B][0-9]{3}/)
      if(briefArr && briefArr.length > 0)
        bezNr = name.split(" ")[0]
        bezirkArr = bezNr.match(/B9([0-9]{2})/)
        if(bezirkArr && bezirkArr.length > 0)
          bezirkArr[1]

  addToDistrictResult: (districtResult, raw) ->
    for i in [0...districtResult.length]
      districtResult[i] += parseInt(raw[i])
    districtResult

  rawForDistrict: (districtStartPosition) ->
    @rawData.slice(districtStartPosition, districtStartPosition+@resultsPerDistrict)

  addRawForDistrict: (raw, districtNumber) ->
    daten = _.find(@data, (d) -> d.wahlbezirk_nr == districtNumber)
    if daten.result.length == 0
      daten.result = raw
    else
      daten.result = @addToDistrictResult(daten.result, raw)

  formatResults: ->
    @data.map (districtResults) =>
      results = @formatRawResults(districtResults.result)
      winningParty = _.max(results, (d) -> d.votes)
      districtResults.winner = winningParty.party
      districtResults.partyPercentages = results
      waehler = districtResults.result[districtResults.result.length-2]
      districtResults.winning_percentage = winningParty.votes / waehler

  formatRawResults: (wahlResults) ->
    partyNames = ['Lewe, Markus (CDU)','K\u00F6hnke, Jochen (SPD)','Klein-Schmeink, Maria (B&#180;90/Die GR\u00DCNEN)','G\u00F6tting, Heinrich (FDP)','Seemann, Harry (Einzelbewerber)',"W\u00E4hler/<BR>innen","Wahlbe-<BR>rechtigte"];
    parties = for i in [0...partyNames.length]
      waehler = wahlResults[wahlResults.length-2]
      votes = wahlResults[i]
      percentage = votes * 100 / waehler
      {party: partyNames[i], votes: votes, percentage: percentage }
