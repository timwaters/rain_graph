Rain Graph
==========

## About

A Ruby Sinatra web application to graph immediate upcoming rain for UK locations.

http://rain-graph.herokuapp.com/

This application shows a graph of precipitation each hour for the next few hours.
It uses the very good metoffice datapoint service: http://metoffice.gov.uk/datapoint

It can be used for any UK location, although certain currently hardcoded versions also have text forecasts.

It caches responses from the API - to avoid hitting the service too much, and also because the service only updates once a hour.


## Things I would like to do

* Dynamically determine the text forecasts for region that the chosen point is in
* Android app it
* Show the precipation forecast map images on mouse hover over points in the graph
* Show plain terrain basemap underneath

## Screenshot


![Rain Graph ScreenShot](http://i.imgur.com/CC0oXhw.png "Rain Graph ScreenShot")
