#' Gives cleanly parsed data
#'
#' Very tightly tied to how https://github.com/metrica-sports/sample-data is
#' organised right now since I don't know how tracking data is otherwise
#' organised. Home team always attacks from left to right, x 0 to x 1.
#'
#' @param cRootPath
#' @examples
#' @import data.table
#' @export
fParseTrackingDataBothTeams = function (
   cRootPath,
   cGameName,
   bOutputLong,
   nXLimit = 120,
   nYLimit = 80,
   xMaxBB = 1,
   yMaxBB = 1,
   nUpperLimitSpeed = 10
) {

   dtTrackingData = merge(
      fParseTrackingDataOneTeam(
         paste0(
            cRootPath, '/',
            cGameName, '/',
            cGameName,
            '_RawTrackingData_Away_Team.csv'
         ),
         cTag = 'Away',
         nXLimit = nXLimit,
         nYLimit = nYLimit,
         xMaxBB = 1,
         yMaxBB = 1
      ),
      fParseTrackingDataOneTeam(
         paste0(
            cRootPath, '/',
            cGameName, '/',
            cGameName,
            '_RawTrackingData_Home_Team.csv'
         ),
         cTag = 'Home',
         nXLimit = nXLimit,
         nYLimit = nYLimit,
         xMaxBB = 1,
         yMaxBB = 1
      ),
      c('Period','Frame','Time_s'),
      all = T
   )

   dtTrackingData[, c('AwayBallX','AwayBallY') := NULL]

    setnames(
        dtTrackingData,
        c('HomeBallX','HomeBallY'),
        c('BallX','BallY')
    )

   dtEventsData = fread(
      paste0(
         paste0(
            cRootPath, '/',
            cGameName, '/',
            cGameName,
            '_RawEventsData.csv'
         )
      )
   )

   setnames(
      dtEventsData,
      c('Start Frame','Start Time [s]','End Frame','End Time [s]'),
      c('StartFrame','StartTime_s','EndFrame','EndTime_s'),
   )

   setnames(
      dtEventsData,
      c('Start X','Start Y','End X','End Y'),
      c('EventStartX','EventStartY','EventEndX','EventEndY'),
   )

   dtEventsData[, EventStartX := EventStartX * nXLimit / xMaxBB]
   dtEventsData[, EventEndX := EventEndX * nXLimit / xMaxBB]
   dtEventsData[, EventStartY := ( yMaxBB - EventStartY ) * nYLimit / xMaxBB]
   dtEventsData[, EventEndY := ( yMaxBB - EventEndY ) * nYLimit / yMaxBB]

   # if ( bOutputLong ) {
   if ( T ) {

      dtTrackingData = fConvertTrackingDataWideToLong(
         dtTrackingData
      )

      # dtEventsData = merge(
      #
      # )

   } else if ( F ) {

      dtTrackingData = merge(
         dtEventsData,
         dtTrackingData,
         c('Period','Frame','Time_s'),
         all = T
      )

   }

   iFlipPeriod = dtTrackingData[
      Frame %in% dtEventsData[
         Subtype == 'KICK OFF',
         list(Frame = min(StartFrame)),
         Period
      ][,
         Frame
      ]
   ][,
      mean(X),
      list(Period, Tag)
   ][
      Tag == 'Home' & V1 > nXLimit / 2,
      Period
   ]

   dtTrackingData[
      Period %in% iFlipPeriod,
      X := nXLimit - X
   ]

   dtTrackingData[
      Period %in% iFlipPeriod,
      Y := nYLimit - Y
   ]

   dtEventsData[
      Period %in% iFlipPeriod,
      EventStartX := nXLimit - EventStartX
   ]

   dtEventsData[
      Period %in% iFlipPeriod,
      EventStartY := nYLimit - EventStartY
   ]

   dtEventsData[
      Period %in% iFlipPeriod,
      EventEndX := nXLimit - EventEndX
   ]

   dtEventsData[
      Period %in% iFlipPeriod,
      EventEndY := nYLimit - EventEndY
   ]

   setorder(
       dtTrackingData,
       Frame,
       Player
   )


   dtTrackingData[,
        Velocity := c(
            0,
           (
                (
                    ( diff(X) ^ 2 ) +
                    ( diff(Y) ^ 2 )
                ) ^ 0.5
            ) / diff(Time_s)
        ),
        list(
            Player
        )
    ]


    dtTrackingData[,
        VelocityX := c(
            0,
            diff(X) / diff(Time_s)
        ),
        list(
            Player
        )
    ]

    dtTrackingData[,
        VelocityY := c(
            0,
            diff(Y) / diff(Time_s)
        ),
        list(
           Player
        )
   ]

    dtTrackingData[
        Velocity > nUpperLimitSpeed,
        Velocity := nUpperLimitSpeed
    ]


   lData = list(
       dtTrackingData = dtTrackingData,
       dtEventsData = dtEventsData
   )

   lData

}
