#!/bin/bash
echo "Creating Directory..."
date=`date "+%b%d"_"%Y"`
date2=`date +%D`
mkdir -p /home/aayush/stocksdir/$date
echo "Copying Files..."
cd /home/aayush/stocksdir/
`sudo cp getcurlzacks.sh /home/aayush/stocksdir/$date/ && cp rankingsbatch.sh /home/aayush/stocksdir/$date && cp readfilegets /home/aayush/stocksdir/$date/ && cp snp.txt /home/aayush/stocksdir/$date/`
cd /home/aayush/stocksdir/$date
echo "Downloading Info From Zacks.com ..."
`./getcurlzacks.sh`
validate1=`ls *.dat | wc -l`
echo "Importing Into SQL"
`./rankingsbatch.sh > rankings.sql`
vi -c ':1,$s/^/INSERT INTO ZACKS_STOCKS VALUES(' -c ':1,$s/$/);' -c ':wq' rankings.sql
`sudo cp rankings.sql ../zacks`
cd ../zacks
sqlite3 test.db ".read rankings.sql"
echo "Successfully Imported Information"
echo "Validating Stocks..."
validate2=$(sqlite3 test.db "select count(*) from ZACKS_STOCKS where DATE=\"$date2\";")
if [ $validate1 == $validate2 ]; then
  echo "Successfully Validated Stocks!"
else
  echo "Dates do not match, terminating program."
  exit
fi 
echo "Running diffrank.sh"
`./diffrank.sh | grep -v -E "went|Different|^ *$" > sortedstocks.txt`
`cat sortedstocks.txt | awk -F "|" '{print " { \n \"Date\":\"" $1 "\", \n \"Symbol\":\"" $2 "\", \n     \"Name\":\"" $3     "\", \n \"Price\":\"" $4 "\", \n \"Rank\":\"" $5 "\" \n },"}' > sortedstocks.json`
vi -c ':1s/{/[ {' -c ':$s/},/} ]' -c ':wq' sortedstocks.json
`sudo cp sortedstocks.json ../../renderstocks`
cd ../../renderstocks
node createTable.js


vi -c ':1,$s/<td><\/td>//g' -c ':1,$s/<td>start<\/td>/<table id=\"table_id\"> \n<tr> \n<th>Date<\/t    d> \n<th>Symbol<\/td> \n<th>Name<\/td> \n<th>Price<\/td> \n<th>Rank<\/th> \n<tr>' -c ':1,$s/<td>end    <\/td>/<\/table> \n<br> \n<br>' -c ':1,$s/<td>1-Strong Buy/<td class=\"y_n\">1-Strong Buy' -c ':1,$    s/<td>2-Buy/<td class=\"y_n\">2-Buy' -c ':1,$s/<td>3-Hold/<td class=\"y_n\">3-Hold' -c ':1,$s/<td>4    -Sell/<td class=\"y_n\">4-Sell' -c ':1,$s/<td>5-Strong Sell/<td class=\"y_n\">5-Strong Sell' -c ':wq' build.html

sed -i '/<head>/a <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/    1.4.4/jquery.js"></script> <script type="text/javascript"> $(document).ready(function(){ $("#table_    id td.y_n").each(function(){ if ($(this).text() == "4-Sell") { $(this).css("background-color","#FF2    828"); } if ($(this).text() == "2-Buy") { $(this).css("background-color","#41BB00"); } if ($(this).    text() == "3-Hold") { $(this).css("background-color","#FF971C"); } if ($(this).text() == "1-Strong     Buy") { $(this).css("background-color","#C5FF00"); } if ($(this).text() == "5-Strong Sell") { $(thi    s).css("background-color","#A50000"); } });});</script>' /home/aayush/renderstocks/build.html

`sudo cp build.html /var/www/html`
