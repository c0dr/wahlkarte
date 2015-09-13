---
---
templates = []
geoData = {}
votingData = {}
votingMap = {}
partyResults = ->
  templates = parseTemplates(["tooltip","detail"])
  daten = votingData["2015"]["districts"]
  data = geoData["districts"]
  daten.map (d) ->
    parties = ['Lewe, Markus (CDU)','K\u00F6hnke, Jochen (SPD)','Klein-Schmeink, Maria (B&#180;90/Die GR\u00DCNEN)','G\u00F6tting, Heinrich (FDP)','Seemann, Harry (Einzelbewerber)',"W\u00E4hler/<BR>innen","Wahlbe-<BR>rechtigte"].map((partyName) -> makeParty(d,partyName))
    d.winner = _.max(parties, (d) -> d.votes; ).party
    d.partyPercentages = parties
    d.winning_percentage = d[d.winner] / d.waehler_insgesamt
    d.wahlbezirk_nr = parseInt(d.wahlbezirk_nr)
    d
  options = { width: 960, height: 600, zoomPercentage: 0.4 }
  votingMap = new VotingMap(data,daten,options)
  mapKeys = { featureClassKey: "winner", districtKey: "bezirk_nr", dataDistrictKey: "wahlbezirk_nr", opacityKey: "winning_percentage" }
  votingMap.setKeys(mapKeys)
  votingMap.tooltipHtml = (d) ->
    data = @dataForFeature(d)
    context = { bezirk: d.properties.bezirk_nam, partyName: partyName(data.winner), percentage: Math.ceil(data.winning_percentage*100) }
    templates.tooltip(context)
  votingMap.detailResults = (d) ->
    data = @dataForFeature(d)
    partyList = _.sortBy(data.partyPercentages, (party) -> party.percentage).reverse()
    context = { parties: partyList, districtName: d.properties.bezirk_nam }
    templates.detail(context)
  #votingMap.featureClass = (d) -> "spd"
#      votingMap.featureOpacity = (d) =>
#        data = @dataForFeature(d)
#        data.partyPercentages.spd / d.waehler_insgesamt
#      votingMap.opacityKey = (d) -> "spd_percentage"
  votingMap.render("map")

districtResults = ->
  templates = parseTemplates(["tooltip","detail"]) unless templates
  daten = votingData["2015"]["districts"]
  data = geoData["districts"]
  options = {
    width: $('#vote-map').width()
    height: 600
    zoomPercentage: 0.4
    margin: { top: 0, left: 0 }
  }
  votingMap = new VotingMap(data,daten,options)
  mapKeys = { featureClassKey: "winner", districtKey: "wahlbezirk", dataDistrictKey: "wahlbezirk_nr", opacityKey: "winning_percentage", districtName: "bezirkname" }
  votingMap.setKeys(mapKeys)
  votingMap.tooltipHtml = (d) ->
    data = @dataForFeature(d)
    context = { bezirk: d.properties[@districtName], partyName: partyName(data.winner), percentage: Math.ceil(data.winning_percentage*100) }
    templates.tooltip(context)
  votingMap.detailResults = (d) ->
    data = @dataForFeature(d)
    partyList = _.sortBy(data.partyPercentages, (party) -> party.percentage).reverse()
    context = { parties: partyList, districtName: d.properties.bezirk_nam }
    templates.detail(context)
  votingMap.render("vote-map")

subDistrictData = ->
  voteData = new Votes2015(votingData["2015"]["erg"], [], votingData["2015"]["beznamen"])
  voteData.setResultsPerDistrict(votingData["2015"]["resultsPerDistrict"])
  voteData.formatForSubDistricts()
  votingData["2015"]["districts"] = voteData.data
  voteData.data

districtData = ->
  voteData = new Votes2015(votingData["2015"]["erg"], votingData["2015"]["raw"], votingData["2015"]["beznamen"])
  voteData.setResultsPerDistrict(votingData["2015"]["resultsPerDistrict"])
  voteData.formatForDistricts()
  votingData["2015"]["districts"] = voteData.data
  voteData.data

updateVoteMapForSubDistricts = ->
  mapKeys = { featureClassKey: "winner", districtKey: "bezirk_nr", dataDistrictKey: "wahlbezirk_nr", opacityKey: "winning_percentage", districtName: "bezirk_nam" }
  geojson = geoData["subDistricts"]
  data = subDistrictData()
  updatVotingMapWithDistrictsAndData(geojson, data, mapKeys)

updateVoteMapForDistricts = ->
  mapKeys = { featureClassKey: "winner", districtKey: "wahlbezirk", dataDistrictKey: "wahlbezirk_nr", opacityKey: "winning_percentage", districtName: "bezirkname" }
  geojson = geoData["districts"]
  data = districtData()
  updatVotingMapWithDistrictsAndData(geojson, data, mapKeys)

updatVotingMapWithDistrictsAndData = (districts, data, mapKeys) ->
  votingMap.setKeys(mapKeys)
  votingMap.update(districts, data)

init = ->
  d3.json "wahlbezirke.geojson", (err, data) ->
    geoData["districts"] = data
    d3.json "stimmbezirke.geojson", (err, data) ->
      geoData["subDistricts"] = data
      votingData["2015"] = {}
      jQuery.ajax({
        url: "http://crossorigin.me/http://www.stadt-muenster.de/ms/wahlen/ergebnis/app/bw2015.js",
        dataType: "script",
        success: (data, ts,jq) ->
          d3.json("wahlbezirke.json", (err, data) ->
            votingData["2015"]["raw"] = data
            votingData["2015"]["erg"] = erg
            votingData["2015"]["beznamen"] = beznamen
            votingData["2015"]["resultsPerDistrict"] = pnamen.length
            districtData()
            districtResults()
          )
        }
      )
$ ->
  templates = parseTemplates(["tooltip","detail"])
  init()
  $('form#types').on('change', 'input[type=radio]', (e) ->
    if this.value == 'districts'
      updateVoteMapForDistricts()
    else
      updateVoteMapForSubDistricts()
  )
  $('#map-controll #extent a').click (e) ->
    d3.select("#extent").classed('active', false)
    votingMap.reset()
