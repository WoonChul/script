#!/bin/sh
# the next line restarts using wish\
exec wish "$0" "$@" 

if {![info exists vTcl(sourcing)]} {

    # Provoke name search
    catch {package require bogus-package-name}
    set packageNames [package names]

    package require BWidget
    switch $tcl_platform(platform) {
	windows {
	}
	default {
	    option add *ScrolledWindow.size 14
	}
    }
    
    package require Tk
    switch $tcl_platform(platform) {
	windows {
            option add *Button.padY 0
	}
	default {
            option add *Scrollbar.width 10
            option add *Scrollbar.highlightThickness 0
            option add *Scrollbar.elementBorderWidth 2
            option add *Scrollbar.borderWidth 2
	}
    }
    
        # tablelist is required
        package require tablelist
    
}

#############################################################################
# Visual Tcl v1.60 Project
#


#############################################################################
# vTcl Code to Load Stock Fonts


if {![info exist vTcl(sourcing)]} {
set vTcl(fonts,counter) 0
#############################################################################
## Procedure:  vTcl:font:add_font

proc ::vTcl:font:add_font {font_descr font_type {newkey {}}} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    if {[info exists ::vTcl(fonts,$font_descr,object)]} {
        ## cool, it already exists
        return $::vTcl(fonts,$font_descr,object)
    }

     incr ::vTcl(fonts,counter)
     set newfont [eval font create $font_descr]
     lappend ::vTcl(fonts,objects) $newfont

     ## each font has its unique key so that when a project is
     ## reloaded, the key is used to find the font description
     if {$newkey == ""} {
          set newkey vTcl:font$::vTcl(fonts,counter)

          ## let's find an unused font key
          while {[vTcl:font:get_font $newkey] != ""} {
             incr ::vTcl(fonts,counter)
             set newkey vTcl:font$::vTcl(fonts,counter)
          }
     }

     set ::vTcl(fonts,$newfont,type)       $font_type
     set ::vTcl(fonts,$newfont,key)        $newkey
     set ::vTcl(fonts,$newfont,font_descr) $font_descr
     set ::vTcl(fonts,$font_descr,object)  $newfont
     set ::vTcl(fonts,$newkey,object)      $newfont

     lappend ::vTcl(fonts,$font_type) $newfont

     ## in case caller needs it
     return $newfont
}

#############################################################################
## Procedure:  vTcl:font:getFontFromDescr

proc ::vTcl:font:getFontFromDescr {font_descr} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    if {[info exists ::vTcl(fonts,$font_descr,object)]} {
        return $::vTcl(fonts,$font_descr,object)
    } else {
        return ""
    }
}

}
#############################################################################
# vTcl Code to Load User Fonts

vTcl:font:add_font \
    "-family helvetica -size 20 -weight bold -slant roman -underline 0 -overstrike 0" \
    user \
    vTcl:font11
#################################
# VTCL LIBRARY PROCEDURES
#

if {![info exists vTcl(sourcing)]} {
#############################################################################
## Library Procedure:  Window

proc ::Window {args} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    global vTcl
    foreach {cmd name newname} [lrange $args 0 2] {}
    set rest    [lrange $args 3 end]
    if {$name == "" || $cmd == ""} { return }
    if {$newname == ""} { set newname $name }
    if {$name == "."} { wm withdraw $name; return }
    set exists [winfo exists $newname]
    switch $cmd {
        show {
            if {$exists} {
                wm deiconify $newname
            } elseif {[info procs vTclWindow$name] != ""} {
                eval "vTclWindow$name $newname $rest"
            }
            if {[winfo exists $newname] && [wm state $newname] == "normal"} {
                vTcl:FireEvent $newname <<Show>>
            }
        }
        hide    {
            if {$exists} {
                wm withdraw $newname
                vTcl:FireEvent $newname <<Hide>>
                return}
        }
        iconify { if $exists {wm iconify $newname; return} }
        destroy { if $exists {destroy $newname; return} }
    }
}
#############################################################################
## Library Procedure:  vTcl:DefineAlias

proc ::vTcl:DefineAlias {target alias widgetProc top_or_alias cmdalias} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    global widget
    set widget($alias) $target
    set widget(rev,$target) $alias
    if {$cmdalias} {
        interp alias {} $alias {} $widgetProc $target
    }
    if {$top_or_alias != ""} {
        set widget($top_or_alias,$alias) $target
        if {$cmdalias} {
            interp alias {} $top_or_alias.$alias {} $widgetProc $target
        }
    }
}
#############################################################################
## Library Procedure:  vTcl:DoCmdOption

proc ::vTcl:DoCmdOption {target cmd} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    ## menus are considered toplevel windows
    set parent $target
    while {[winfo class $parent] == "Menu"} {
        set parent [winfo parent $parent]
    }

    regsub -all {\%widget} $cmd $target cmd
    regsub -all {\%top} $cmd [winfo toplevel $parent] cmd

    uplevel #0 [list eval $cmd]
}
#############################################################################
## Library Procedure:  vTcl:FireEvent

proc ::vTcl:FireEvent {target event {params {}}} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    ## The window may have disappeared
    if {![winfo exists $target]} return
    ## Process each binding tag, looking for the event
    foreach bindtag [bindtags $target] {
        set tag_events [bind $bindtag]
        set stop_processing 0
        foreach tag_event $tag_events {
            if {$tag_event == $event} {
                set bind_code [bind $bindtag $tag_event]
                foreach rep "\{%W $target\} $params" {
                    regsub -all [lindex $rep 0] $bind_code [lindex $rep 1] bind_code
                }
                set result [catch {uplevel #0 $bind_code} errortext]
                if {$result == 3} {
                    ## break exception, stop processing
                    set stop_processing 1
                } elseif {$result != 0} {
                    bgerror $errortext
                }
                break
            }
        }
        if {$stop_processing} {break}
    }
}
#############################################################################
## Library Procedure:  vTcl:Toplevel:WidgetProc

proc ::vTcl:Toplevel:WidgetProc {w args} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    if {[llength $args] == 0} {
        ## If no arguments, returns the path the alias points to
        return $w
    }
    set command [lindex $args 0]
    set args [lrange $args 1 end]
    switch -- [string tolower $command] {
        "setvar" {
            foreach {varname value} $args {}
            if {$value == ""} {
                return [set ::${w}::${varname}]
            } else {
                return [set ::${w}::${varname} $value]
            }
        }
        "hide" - "show" {
            Window [string tolower $command] $w
        }
        "showmodal" {
            ## modal dialog ends when window is destroyed
            Window show $w; raise $w
            grab $w; tkwait window $w; grab release $w
        }
        "startmodal" {
            ## ends when endmodal called
            Window show $w; raise $w
            set ::${w}::_modal 1
            grab $w; tkwait variable ::${w}::_modal; grab release $w
        }
        "endmodal" {
            ## ends modal dialog started with startmodal, argument is var name
            set ::${w}::_modal 0
            Window hide $w
        }
        default {
            uplevel $w $command $args
        }
    }
}
#############################################################################
## Library Procedure:  vTcl:WidgetProc

proc ::vTcl:WidgetProc {w args} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    if {[llength $args] == 0} {
        ## If no arguments, returns the path the alias points to
        return $w
    }

    set command [lindex $args 0]
    set args [lrange $args 1 end]
    uplevel $w $command $args
}
#############################################################################
## Library Procedure:  vTcl:toplevel

proc ::vTcl:toplevel {args} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    uplevel #0 eval toplevel $args
    set target [lindex $args 0]
    namespace eval ::$target {set _modal 0}
}
}


if {[info exists vTcl(sourcing)]} {

proc vTcl:project:info {} {
    set base .top66
    namespace eval ::widgets::$base {
        set set,origin 1
        set set,size 1
        set runvisible 0
    }
    namespace eval ::widgets::$base.lab69 {
        array set save {-foreground 1 -height 1 -highlightcolor 1 -text 1 -width 1}
    }
    set site_3_0 $base.lab69
    namespace eval ::widgets::$site_3_0.lab72 {
        array set save {-activebackground 1 -activeforeground 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1}
    }
    namespace eval ::widgets::$site_3_0.lab73 {
        array set save {-activebackground 1 -activeforeground 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -textvariable 1 -width 1}
    }
    namespace eval ::widgets::$base.lab67 {
        array set save {-foreground 1 -height 1 -highlightcolor 1 -text 1 -width 1}
    }
    set site_3_0 $base.lab67
    namespace eval ::widgets::$site_3_0.cpd86 {
        array set save {-borderwidth 1 -height 1 -highlightcolor 1 -width 1}
    }
    set site_4_0 $site_3_0.cpd86
    namespace eval ::widgets::$site_4_0.fra76 {
        array set save {-borderwidth 1 -height 1 -highlightcolor 1 -width 1}
    }
    set site_5_0 $site_4_0.fra76
    namespace eval ::widgets::$site_5_0.cpd77 {
        array set save {-activebackground 1 -activeforeground 1 -command 1 -disabledforeground 1 -font 1 -foreground 1 -highlightcolor 1 -text 1}
    }
    namespace eval ::widgets::$site_4_0.lab78 {
        array set save {-foreground 1 -height 1 -highlightcolor 1 -relief 1 -text 1 -width 1}
    }
    set site_5_0 $site_4_0.lab78
    namespace eval ::widgets::$site_5_0.lab67 {
        array set save {-activebackground 1 -activeforeground 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1}
    }
    namespace eval ::widgets::$site_5_0.cpd68 {
        array set save {-background 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -insertbackground 1 -relief 1 -selectbackground 1 -selectforeground 1 -state 1 -textvariable 1}
    }
    namespace eval ::widgets::$site_5_0.lab84 {
        array set save {-activebackground 1 -activeforeground 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1}
    }
    namespace eval ::widgets::$site_5_0.ent85 {
        array set save {-background 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -insertbackground 1 -relief 1 -selectbackground 1 -selectforeground 1 -state 1 -textvariable 1}
    }
    namespace eval ::widgets::$site_5_0.lab81 {
        array set save {-activebackground 1 -activeforeground 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1}
    }
    namespace eval ::widgets::$site_5_0.ent83 {
        array set save {-background 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -insertbackground 1 -relief 1 -selectbackground 1 -selectforeground 1 -state 1 -textvariable 1}
    }
    namespace eval ::widgets::$site_5_0.lab79 {
        array set save {-activebackground 1 -activeforeground 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1}
    }
    namespace eval ::widgets::$site_5_0.ent80 {
        array set save {-background 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -insertbackground 1 -relief 1 -selectbackground 1 -selectforeground 1 -state 1 -textvariable 1}
    }
    namespace eval ::widgets::$site_4_0.lab90 {
        array set save {-foreground 1 -height 1 -highlightcolor 1 -relief 1 -text 1 -width 1}
    }
    set site_5_0 $site_4_0.lab90
    namespace eval ::widgets::$site_5_0.che91 {
        array set save {-activebackground 1 -activeforeground 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1 -variable 1}
    }
    namespace eval ::widgets::$site_5_0.but67 {
        array set save {-activebackground 1 -activeforeground 1 -command 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1 -textvariable 1}
    }
    namespace eval ::widgets::$site_5_0.sep70 {
        array set save {-background 1}
    }
    namespace eval ::widgets::$site_5_0.che92 {
        array set save {-activebackground 1 -activeforeground 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1 -variable 1}
    }
    namespace eval ::widgets::$site_5_0.but68 {
        array set save {-activebackground 1 -activeforeground 1 -command 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1 -textvariable 1}
    }
    namespace eval ::widgets::$site_5_0.sep71 {
        array set save {-background 1}
    }
    namespace eval ::widgets::$site_5_0.che93 {
        array set save {-activebackground 1 -activeforeground 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1 -variable 1}
    }
    namespace eval ::widgets::$site_5_0.but69 {
        array set save {-activebackground 1 -activeforeground 1 -command 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1 -textvariable 1}
    }
    namespace eval ::widgets::$site_5_0.cpd73 {
        array set save {-background 1}
    }
    namespace eval ::widgets::$site_5_0.che72 {
        array set save {-activebackground 1 -activeforeground 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1 -variable 1}
    }
    namespace eval ::widgets::$site_5_0.cpd74 {
        array set save {-activebackground 1 -activeforeground 1 -command 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1 -textvariable 1}
    }
    namespace eval ::widgets::$site_5_0.cpd72 {
        array set save {-background 1}
    }
    namespace eval ::widgets::$site_5_0.cpd75 {
        array set save {-activebackground 1 -activeforeground 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1 -variable 1}
    }
    namespace eval ::widgets::$site_5_0.cpd76 {
        array set save {-activebackground 1 -activeforeground 1 -command 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1 -textvariable 1}
    }
    namespace eval ::widgets::$site_4_0.lab69 {
        array set save {-foreground 1 -height 1 -highlightcolor 1 -text 1 -width 1}
    }
    set site_5_0 $site_4_0.lab69
    namespace eval ::widgets::$site_5_0.cpd70 {
        array set save {-activebackground 1 -activeforeground 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1}
    }
    namespace eval ::widgets::$site_5_0.cpd71 {
        array set save {-disabledforeground 1 -entrybg 1 -foreground 1 -highlightcolor 1 -insertbackground 1 -modifycmd 1 -postcommand 1 -selectbackground 1 -selectforeground 1 -takefocus 1 -textvariable 1}
    }
    namespace eval ::widgets::$site_4_0.lab88 {
        array set save {-foreground 1 -height 1 -highlightcolor 1 -relief 1 -text 1 -width 1}
    }
    set site_5_0 $site_4_0.lab88
    namespace eval ::widgets::$site_5_0.scr92 {
        array set save {-activebackground 1 -command 1 -highlightcolor 1 -orient 1 -troughcolor 1 -width 1}
    }
    namespace eval ::widgets::$site_5_0.scr91 {
        array set save {-activebackground 1 -command 1 -highlightcolor 1 -troughcolor 1 -width 1}
    }
    namespace eval ::widgets::$site_5_0.tab90 {
        array set save {-columns 1 -columntitles 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -labelheight 1 -labelrelief 1 -listvariable 1 -selectbackground 1 -selectforeground 1 -xscrollcommand 1 -yscrollcommand 1}
    }
    namespace eval ::widgets::$site_4_0.lab89 {
        array set save {-foreground 1 -height 1 -highlightcolor 1 -relief 1 -text 1 -width 1}
    }
    set site_5_0 $site_4_0.lab89
    namespace eval ::widgets::$site_5_0.but75 {
        array set save {-activebackground 1 -activeforeground 1 -command 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1}
    }
    namespace eval ::widgets::$site_5_0.lab70 {
        array set save {-foreground 1 -height 1 -highlightcolor 1 -relief 1 -text 1 -width 1}
    }
    set site_6_0 $site_5_0.lab70
    namespace eval ::widgets::$site_6_0.rad71 {
        array set save {-activebackground 1 -activeforeground 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1 -value 1 -variable 1}
    }
    namespace eval ::widgets::$site_6_0.rad72 {
        array set save {-activebackground 1 -activeforeground 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1 -value 1 -variable 1}
    }
    namespace eval ::widgets::$site_5_0.but68 {
        array set save {-activebackground 1 -activeforeground 1 -background 1 -command 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1}
    }
    namespace eval ::widgets::$site_5_0.but67 {
        array set save {-activebackground 1 -activeforeground 1 -background 1 -command 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1}
    }
    namespace eval ::widgets::$site_5_0.but74 {
        array set save {-activebackground 1 -activeforeground 1 -background 1 -command 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1}
    }
    namespace eval ::widgets::$site_5_0.but69 {
        array set save {-activebackground 1 -activeforeground 1 -background 1 -command 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1}
    }
    namespace eval ::widgets::$site_5_0.but76 {
        array set save {-activebackground 1 -activeforeground 1 -background 1 -command 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1}
    }
    namespace eval ::widgets::$site_5_0.sep77 {
        array set save {}
    }
    namespace eval ::widgets::$site_5_0.cpd78 {
        array set save {-activebackground 1 -activeforeground 1 -background 1 -command 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1}
    }
    namespace eval ::widgets::$site_5_0.cpd79 {
        array set save {-activebackground 1 -activeforeground 1 -background 1 -command 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1}
    }
    namespace eval ::widgets::$site_5_0.cpd82 {
        array set save {}
    }
    namespace eval ::widgets::$site_5_0.cpd80 {
        array set save {-activebackground 1 -activeforeground 1 -background 1 -command 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1}
    }
    namespace eval ::widgets::$site_5_0.cpd81 {
        array set save {-activebackground 1 -activeforeground 1 -background 1 -command 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1}
    }
    namespace eval ::widgets::$base.fra68 {
        array set save {-borderwidth 1 -height 1 -highlightcolor 1 -width 1}
    }
    set site_3_0 $base.fra68
    namespace eval ::widgets::$site_3_0.but71 {
        array set save {-activebackground 1 -activeforeground 1 -command 1 -disabledforeground 1 -foreground 1 -highlightcolor 1 -text 1}
    }
    namespace eval ::widgets_bindings {
        set tagslist _TopLevel
    }
    namespace eval ::vTcl::modules::main {
        set procs {
            init
            main
            init_Value
            pTbl_StartCMD
            pTbl_EndCMD
            pCOMBO_POST
            pEmptyStr
            pTable_ChkButton_IMG
            pSELECT_CLEAR
            pTable_SELECT
            pTable_LYR_REFRESH
            pPath_Modify
            pERP_INFO_LOADING
            pText_Control
            ptest
            pBarcode_Control
            pSub_Create
            pFeatureFile_Text_Control
            pPARA_LPD_IMPORT
            pPlot
            dd
            pXY_SHIFT
            pFilmSize_Chk
            pText_MODIFY
            pBACK_GROUND
            pPARA_LPD_OUTPUT
        }
        set compounds {
        }
        set projectType single
    }
}
}

#################################
# USER DEFINED PROCEDURES
#
#############################################################################
## Procedure:  main

proc ::main {argc argv} {
global env INFO FORM LPD

init_Value $argv

if { $argv == "-b" } {
    pBACK_GROUND
} else {
    Window show .top66
    if {![info exists env(JOB)] && $INFO(OPT) == "" } { tk_messageBox -message "JOB DATA을 열고 실행바랍니다." ; return }
    set FORM(JOB) $env(JOB)
    if { [regsub {\D} [string range $FORM(JOB) 1 1] ""] == "" } { 
        set INFO(LCNT) [expr [scan [string range $FORM(JOB) 1 1] %c]-87] 
    } else { 
        set INFO(LCNT) [string range $FORM(JOB) 1 1] 
    }
    pTable_LYR_REFRESH
}
}
#############################################################################
## Procedure:  init_Value

proc ::init_Value {opt} {
global INFO FORM


##INFO Variable Initilzation

# OS ERP Loading Config
if { [string toupper [exec uname -s]] == "LINUX"  } { 
    set INFO(OS) "LINUX" ; set INFO(RT) "/" 
#    set INFO(ERP) "DRIVER={FreeTDS};DSN={ERP};UID={kcc_design};PWD=kccdesign"
} else {
    set INFO(OS) "WINDOWS" ; set INFO(RT) "c:/" 
#    set INFO(ERP) "DRIVER=SQL Server;DATABASE=KCCDB;UID=kcc_design;PWD=kccdesign;Server=192.168.5.120"
}

set INFO(LCNT) "" 
set INFO(OPT) ""
set INFO(CHK_IMG)    [image create photo -file [file join $INFO(RT) genesis sys nkcc pkg image checked.gif]]
set INFO(UCHK_IMG)   [image create photo -file [file join $INFO(RT) genesis sys nkcc pkg image unchecked.gif]]
set INFO(OUT_LIST)   { "pg" "con*" "silk*" "w-etch*" }
set INFO(JAGURI_SZ)  { "1200" "1000" "2600" "2300" }
set INFO(KEY_NO)     [clock scan seconds]
set INFO(DBPATH)     [file join $INFO(RT) database jobs ]
set INFO(ORPATH)     [file join $INFO(RT) genesis sys nkcc auto LOG OUTPUT_TOOL ]

source [file join $INFO(RT) genesis sys nkcc auto INFO CALLCOMANS.tcl]
source [file join $INFO(RT) genesis sys nkcc auto INFO CALLPROC.tcl]

set INFO(lpd) {adflash advec conductors1 conductors2 conductors3 conductors4 conductors5 copper_area def_ext_lpd device_type 
enl_0_vecs enl_by1 enl_by2 enl_by3 enl_by4 enl_by5 enl_by6 enl_by7 enl_by8 enl_by9 enl_by10 enl_ctr_by enl_img_sym enl_other 
enl_panel enl_pol enl_sym enl_sym_by is_defined media minflash minvec overlap plot_kind1 plot_kind2 polarity quality res_units 
res_value resolution smoothing speed swap_axes sym_name1 sym_name2 sym_name3 sym_name4 sym_name5 sym_name6 sym_name7 sym_name8 
sym_name9 sym_name10 was_input xcenter xcenter_inch xmirror xshift xstretch ycenter ycenter_inch ymirror yshift ystretch }

set INFO(lpd_int) { ADFLASH ADVEC CONDUCTOR1 CONDUCTOR2 CONDUCTOR3 CONDUCTOR4 CONDUCTOR5 COPPER_AREA ENLARGE_CONTOURS_BY ENLARGE_SYMBOLS_BY MINFLASH MINVEC SPEED SYMBOL_ADD1 SYMBOL_ADD10 SYMBOL_ADD2 SYMBOL_ADD3 SYMBOL_ADD4 SYMBOL_ADD5 SYMBOL_ADD6 SYMBOL_ADD7 SYMBOL_ADD8 SYMBOL_ADD9 XCENTER XMIRROR XSHIFT YCENTER YMIRROR YSHIFT }

if { $opt == "-b" } { return }

#FORM Variable Initilzation

set FORM(JOB) "" ; set FORM(STP) "" ; set FORM(LYR) "" ; set FORM(OPT) 1 ; set FORM(OUT_FD) 1 ; set FORM(OUT_AOI) 0 ; set FORM(OUT_DRL) 0 ; set FORM(OUT_GBR) 0

if { [file isfile [file join $INFO(RT) genesis sys nkcc auto OUTPUT config OUTPUT_TOOLs.cfg]] } {
    uplevel #1 [list source  [file join $INFO(RT) genesis sys nkcc auto OUTPUT config OUTPUT_TOOLs.cfg]]
} else {
    set FORM(DI_PATH)    [file join $INFO(RT) home genesis OUTPUT ]
    set FORM(AOI_PATH)   [file join $INFO(RT) home genesis OUTPUT ]
    set FORM(DRILL_PATH) [file join $INFO(RT) home genesis OUTPUT ]
    set FORM(PG_PATH)    [file join $INFO(RT) home genesis OUTPUT ]
    set FORM(GBR_PATH)   [file join $INFO(RT) home genesis OUTPUT ]
    file mkdir [file join $INFO(RT) genesis sys nkcc auto OUTPUT config]
    set f [open [file join $INFO(RT) genesis sys nkcc auto OUTPUT config OUTPUT_TOOLs.cfg] w+]
    foreach item [array names FORM] {
        if {![string match *_PATH $item]} { continue }
        puts $f "set FORM($item) $FORM($item)"
    }
    close $f
}
}
#############################################################################
## Procedure:  pTbl_StartCMD

proc ::pTbl_StartCMD {tbl row col text} {
set w [$tbl editwinpath]

switch -exact -- [$tbl columncget $col -name] {
   POLARITY    { $w configure -values { POSITIVE NEGATIVE } -editable no }
   MIRROR      { $w configure -values { XMIRROR YMIRROR NO_MIRROR } -editable no }
   SWAP        { $w configure -values { SWAP NO_SWAP } -editable no }
   FILMSIZE    { $w configure -values { 24x20 24x28 }  -editable no }
   MACHINE     { $w configure -values { LP9 LP9-2 ODB++ } -editable no }
   RESOLUTION  { $w configure -values { "NONE" "8000dpi(0.125mil)" "10160dpi(2.5micron)" "16000dpi(0.0625mil)" "25400dpi(1micron)" "32000dpi(0.03125mil)" "40640dpi(0.625micron)" "50800dpi(0.5micron)" } -editable no }
   CHECK       {}   
}

return $text
}
#############################################################################
## Procedure:  pTbl_EndCMD

proc ::pTbl_EndCMD {tbl row col text} {
set w [$tbl editwinpath]
switch [$tbl columncget $col -name] {
   CHECK    { pTable_ChkButton_IMG $tbl $row $col $text  }
   XSTRETCH { set text [format "%3.3f" $text] }
   YSTRETCH { set text [format "%3.3f" $text] }
}
return $text
}
#############################################################################
## Procedure:  pCOMBO_POST

proc ::pCOMBO_POST {} {
global widget FORM

DO_INFO -t matrix -e $FORM(JOB)/matrix, units=mm

ComboBox_STP configure -values  $gCOLstep_name
}
#############################################################################
## Procedure:  pEmptyStr

proc ::pEmptyStr {val} {
return ""
}
#############################################################################
## Procedure:  pTable_ChkButton_IMG

proc ::pTable_ChkButton_IMG {tbl row col text} {
global widget INFO
set img [expr {$text ? $INFO(CHK_IMG) : $INFO(UCHK_IMG)}]
$tbl cellconfigure $row,$col -image $img
$tbl cellconfigure $row,$col -text $text
return
}
#############################################################################
## Procedure:  pSELECT_CLEAR

proc ::pSELECT_CLEAR {} {
global widget FORM

set cnt 0
foreach row $FORM(LYR_SEL) { pTable_ChkButton_IMG "Tablelist_LYR" $cnt 13 0 ; incr cnt }
}
#############################################################################
## Procedure:  pTable_SELECT

proc ::pTable_SELECT {SOURCE_LIST COMPARE_LIST CLEAR} {
global widget

if { $CLEAR } { pSELECT_CLEAR }

set cnt 0
foreach row $SOURCE_LIST {
   foreach rule $COMPARE_LIST {
       if { [string match $rule [lindex $row 0]] } { pTable_ChkButton_IMG "Tablelist_LYR" $cnt 13 1 }
   }
   incr cnt
}

return
}
#############################################################################
## Procedure:  pTable_LYR_REFRESH

proc ::pTable_LYR_REFRESH {} {
global widget FORM INFO

DO_INFO -t matrix -e $FORM(JOB)/matrix, units=mm

Tablelist_LYR delete 0 end
Tablelist_LYR configure -editstartcommand pTbl_StartCMD -editendcommand pTbl_EndCMD

set cnt 0
foreach lyr $gROWname con $gROWcontext lt $gROWlayer_type { 
    set name_chk 0
    foreach rule $INFO(OUT_LIST) {
        if { [string match $rule $lyr] } { set name_chk 1 }
    }

    if { !($name_chk || $con == "board") } { continue }
    
    lappend FORM(LYR_SEL) [list "$lyr" $lt "" "" "" "" "" "" "" "" "" 1 "" 0]
    pTable_ChkButton_IMG "Tablelist_LYR" $cnt 13 0
    switch -exact -- $lt {
        silk_screen  { Tablelist_LYR rowconfigure $cnt -bg white -fg black      }
        solder_mask  { Tablelist_LYR rowconfigure $cnt -bg green -fg black      }
        signal       { 
                       if { $con == "board" } {
                           Tablelist_LYR rowconfigure $cnt -bg orange -fg black
                       } else {
                           Tablelist_LYR rowconfigure $cnt -bg blue   -fg white
                       }
        }
        power_ground { Tablelist_LYR rowconfigure $cnt -bg tomato   -fg black   }
        rout         { Tablelist_LYR rowconfigure $cnt -bg yellow   -fg black   }
        drill        { Tablelist_LYR rowconfigure $cnt -bg darkgray -fg black   }
        default      {}
    }
    incr cnt
}

return
}
#############################################################################
## Procedure:  pPath_Modify

proc ::pPath_Modify {valName} {
global FORM

set dir [tk_chooseDirectory -initialdir [subst $$valName]]
if { $dir == "" } {
    tk_messageBox -message " 디렉토리가 지정되지 않았습니다. / 기본 디렉토리로 설정합니다. "
} else {
    set $valName $dir
    set f [open "/genesis/sys/nkcc/auto/OUTPUT/config/OUTPUT_TOOLs.cfg" w+]
    foreach item [array names FORM] {
        if {![string match *_PATH $item]} { continue }
        puts $f "set FORM($item) $FORM($item)"
    }
    close $f
}
}
#############################################################################
## Procedure:  pERP_INFO_LOADING

proc ::pERP_INFO_LOADING {} {
#global widget  INFO FORM
#package require tdbc::odbc

## ERP Loading 

#set INFO(cn) [tdbc::odbc::connection create db $INFO(ERP)]

#set nowTime [clock scan now]

#if { $FORM(STIME) } { 
#     set INFO(StartDate) [clock format [expr $nowTime - 86400] -format "%Y/%m/%d %H:%M:%S"] 
#     set INFO(EndDate) [clock format $nowTime -format "%Y/%m/%d %H:%M:%S"]
#} else { 
#     set INFO(StartDate) "[Date_Start get] 00:00:00" ; set INFO(EndDate) "[Date_End get] 23:59:59" 
#}

#tk_messageBox -message "$INFO(StartDate) - $INFO(EndDate)"

#if { $FORM(PLOTCHK) != 0 } { set prchk "N" } else { set prchk "Y" } 

#if { $prchk == "N" } {
#    if { [string trim $FORM(PRDT)] == "" } {
#        set MESList [$INFO(cn) allrows "select prdt_code8,film_rev,uniq_no,layer_side,reqt_qty,date_code_type,ISNULL(date_code,''),ISNULL(x_cont,0),ISNULL(y_cont,0),ISNULL(mes_x_cont,100),ISNULL(mes_y_cont,100),reqt_desc from VWD_PLOT_REG where film_dlv_date between '$INFO(StartDate)' and '$INFO(EndDate)' and plot_strt_yn='$prchk'"]
#    } else {
#        set MESList [$INFO(cn) allrows "select prdt_code8,film_rev,uniq_no,layer_side,reqt_qty,date_code_type,ISNULL(date_code,''),ISNULL(x_cont,0),ISNULL(y_cont,0),ISNULL(mes_x_cont,100),ISNULL(mes_y_cont,100),reqt_desc from VWD_PLOT_REG where film_dlv_date between '$INFO(StartDate)' and '$INFO(EndDate)' and plot_strt_yn='$prchk' and prdt_code='$FORM(PRDT)01' "]
#    }
#} else {
#    if { [string trim $FORM(PRDT)] == "" } {
#        set MESList [$INFO(cn) allrows "select prdt_code8,film_rev,uniq_no,layer_side,reqt_qty,date_code_type,ISNULL(date_code,''),ISNULL(x_cont,0),ISNULL(y_cont,0),ISNULL(mes_x_cont,100),ISNULL(mes_y_cont,100),reqt_desc from VWD_PLOT_REG where plot_date between '$INFO(StartDate)' and '$INFO(EndDate)' and plot_strt_yn='$prchk'"]
#    } else {
#        set MESList [$INFO(cn) allrows "select prdt_code8,film_rev,uniq_no,layer_side,reqt_qty,date_code_type,ISNULL(date_code,''),ISNULL(x_cont,0),ISNULL(y_cont,0),ISNULL(mes_x_cont,100),ISNULL(mes_y_cont,100),reqt_desc from VWD_PLOT_REG where plot_date between '$INFO(StartDate)' and '$INFO(EndDate)'and plot_strt_yn='$prchk' and prdt_code='$FORM(PRDT)01'"]
#    }
#}

#$INFO(cn) close

#puts $MESList

#Tablelist_ERP delete 0 end

#set cnt 1
#foreach i $MESList {
#set PRDTNO   [lindex $i 1] 
#set REV      [lindex $i 3] 
#set FILMNO   [lindex $i 5] 
#set FILMTYPE [lindex $i 7] 
#set PLOTCNT  [lindex $i 9] 
#set DATETYPE [lindex $i 11] 
#set DATE     [string trim [lindex $i 13]]
#set XSTRETCH [format "%3.3f" [lindex $i 15]]
#set YSTRETCH [format "%3.3f" [lindex $i 17]]
#set XSTRmes  [format "%3.3f" [lindex $i 19]]
#set YSTRmes  [format "%3.3f" [lindex $i 21]]
#set ETC      [lindex $i 23]

#if { $XSTRETCH == 0 } { set XSTRETCH "" } ; if { $YSTRETCH == 0 } { set YSTRETCH "" }

#lappend FORM(ERP) [list $PRDTNO $REV $FILMNO $FILMTYPE $PLOTCNT $DATETYPE $DATE $XSTRETCH $YSTRETCH $XSTRmes $YSTRmes $ETC  ]

#if { $XSTRETCH != "" && $YSTRETCH != "" } {
#    if { [expr $XSTRETCH - $XSTRmes] < 0.02 && [expr $XSTRETCH - $XSTRmes] > -0.02 } {
#        if { !([expr $YSTRETCH - $YSTRmes] < 0.02 && [expr $YSTRETCH - $YSTRmes] > -0.02) } {
#            Tablelist_ERP rowconfigure  [expr $cnt-1]    -bg red
#            Tablelist_ERP cellconfigure [expr $cnt-1],8  -fg white
#            Tablelist_ERP cellconfigure [expr $cnt-1],9  -fg white
#            Tablelist_ERP cellconfigure [expr $cnt-1],10 -fg white
#            Tablelist_ERP cellconfigure [expr $cnt-1],11 -fg white
#        }
#    } else {
#         Tablelist_ERP rowconfigure  [expr $cnt-1]    -bg red
#         Tablelist_ERP cellconfigure [expr $cnt-1],8  -fg white
#         Tablelist_ERP cellconfigure [expr $cnt-1],9  -fg white
#         Tablelist_ERP cellconfigure [expr $cnt-1],10 -fg white
#         Tablelist_ERP cellconfigure [expr $cnt-1],11 -fg white
#    }
#}
#incr cnt
#}
}
#############################################################################
## Procedure:  pText_Control

proc ::pText_Control {job stp lyr opt args} {
set cnt 0
set txtSou "" ; set txtTar ""
set txtSou [lindex $args 0]

OPTION_CLEAR
COM display_layer,name=$lyr,display=yes,number=1
COM work_layer,name=$lyr

DO_INFO1 -t layer -e $job/$stp/$lyr -d FEATURES, units=mm
if { $opt == "m" || $opt == "f" } {
foreach line $::data {
    if { [string match "#T*" $line] && [string match "*$txtSou*" $line] } {
        incr cnt
        if { $opt == "f" } { continue }
        set txtTar [lindex $args 1]
        set txtPoX [lindex $line 1] ; set txtPoY [lindex $line 2]
        set txtTyp [lindex $line 3] ; set txtPol [string toupper [lindex $line 4]]
        set txtAng [lindex $line 5] ; set txtMir [string toupper [lindex $line 6]]
        set txtXle [lindex $line 7] ; set txtYle [lindex $line 8]
        set txtWid [lindex $line 9] ; set txtLen [string length $txtTar]
        
        if { $txtMir == "Y" } { set txtCen [expr $txtPox - ($txtLen * $txtXle)] ; set txtMir "yes" } else { set txtCen [expr $txtPoX + ($txtLen * $txtXle)] ; set txtMir "no" }
        if { $txtPol == "P" } { set txtPol "positive" } else { set txtPol "negative" }

        COM filter_reset,filter_name=popup
        COM filter_area_strt
        COM filter_area_xy,x=[expr $txtPoX-0.1],y=[expr $txtPoY-0.1]
        COM filter_area_xy,x=[expr $txtPoX+0.1],y=[expr $txtPoY+0.1]
        COM filter_area_end,layer=,filter_name=popup,operation=select,area_type=rectangle,inside_area=yes,intersect_area=no

        COM sel_change_txt,text=$txtTar,x_size=$txtXle,y_size=$txtYle,w_factor=$txtWid,polarity=$txtPol,angle=$txtAng,mirror=$txtMir,fontname=$txtTyp
        COM sel_clear_feat
    } 
}

} elseif { $opt == "a" } {
    set txtXpo [lindex $args 1] ; set txtYpo [lindex $args 2]
    set txtMir [lindex $args 3]
    set txtXle [expr [lindex $args 4]*0.001] ; set txtYle [expr [lindex $args 5]*0.001]

### line width to factor cal - 1unit == 12mil ex) micron 1270um width saving to -> 1270 / 304.8 == 4.166666~
### save and change factor / Text Adding - width / Info manager Feature to change equl

    set txtWfa [expr [lindex $args 6]/304.8]
    set txtPol [lindex $args 7] ; set txtAng [lindex $args 8]
    set txtFon [lindex $args 9]
    
    set para "add_text,attributes=no,type=string,x=$txtXpo,y=$txtYpo,text=$txtSou, x_size=$txtXle,y_size=$txtYle,w_factor=$txtWfa,polarity=$txtPol, angle=$txtAng,mirror=$txtMir,fontname=$txtFon,ver=1"
    COM $para
} else {
  tk_messageBox -message " 옵션을 확인 하여 주세요 !!! "
}

OPTION_CLEAR
return $cnt
}
#############################################################################
## Procedure:  ptest

proc ::ptest {} {
global widget FORM

pFeatureFile_Text_Control $INFO(DBPATH) $FORM(JOB) $FORM(STP) 3 m

#OPEN_JOB_STEP_OPTION_CLEAR $FORM(JOB) $FORM(STP)


#puts [pText_Control $FORM(JOB) $FORM(STP) 1 a "WWYY" 500 600 NO 1524 1524 127 positive 0 standard]
#puts [pText_Control $FORM(JOB) $FORM(STP) 1 a "WWYY-1" 500 500 NO 1524 1524 127 positive 0 standard]
#puts [pText_Control $FORM(JOB) $FORM(STP) 1 f "WWYY-1"]
#puts [pText_Control $FORM(JOB) $FORM(STP) 1 m "WWYY-1" "YYYYYY"]

#puts [pBarcode_Control $FORM(JOB) $FORM(STP) 1 a "WWYY-CCCC" 24x28 NO_MIRROR]
#puts [pBarcode_Control $FORM(JOB) $FORM(STP) 1 f "WWYY-CCCC"]
#puts [pBarcode_Control $FORM(JOB) $FORM(STP) 1 m "WWYY-CCCC" "WWYY-bbbb"]
#pJaguri_Text_Modify $FORM(JOB) $FORM(STP) 2 1
#tk_messageBox -message " Complite "

return 
}
#############################################################################
## Procedure:  pBarcode_Control

proc ::pBarcode_Control {job stp lyr opt args} {
set cnt 0 ; set bcl 20.828
set txtSou "" ; set txtTar ""
set txtSou [lindex $args 0]

OPTION_CLEAR
COM display_layer,name=$lyr,display=yes,number=1
COM work_layer,name=$lyr

DO_INFO1 -t layer -e $job/$stp/$lyr -d FEATURES, units=mm
if { $opt == "m" || $opt == "f" } {    
    foreach line $::data {
        if { [string match  "#B*" $line] && [string match "*$txtSou*" $line] } {
            incr cnt 
            if { $opt == "f" } { continue }
            set txtTar [lindex $args 1]
            set txtPoX [lindex $line 1] ; set txtPoY [lindex $line 2]
            set txtTyp [lindex $line 3] ; set txtPol [string toupper [lindex $line 4]]
            set txtAng [lindex $line 5] ; set txtMir [string toupper [lindex $line 6]]
            set txtXle [lindex $line 7] ; set txtYle [lindex $line 8]
            set txtWid [lindex $line 9] ; set txtLen [string length $txtTar]
            
            if { $txtMir == "Y" } { set xc [expr $txtPox - $bcl ] ; set txtMir "yes" } else { set xc [expr $txtPoX + $bcl ] ; set txtMir "no" }
            if { $txtPol == "P" } { set txtPol "positive" } else { set txtPol "negative" }
            
            COM filter_reset,filter_name=popup
            COM filter_area_strt
            COM filter_area_xy,x=[expr $txtPoX-0.1],y=[expr $txtPoY-0.1]
            COM filter_area_xy,x=[expr $txtPoX+0.1],y=[expr $txtPoY+0.1]
            COM filter_area_end,layer=,filter_name=popup,operation=select,area_type=rectangle,inside_area=yes,intersect_area=no
                                    
            COM sel_change_txt,text=$txtTar,polarity=no_change,angle=-1,mirror=no_change,fontname=
            COM sel_clear_feat
        }
    }
} elseif { $opt == "a" } {
    set fls [lindex $args 1]
    set ls [lindex $args 2]
    if { [string toupper $fls] == "24X20" } {
        if { [string match "NO_MIRROR" [string toupper $ls]] } { 
            set txtPoX [expr 350.944+41.656] ; set txtCen [expr $txtPoX-$bcl] ; set txtMir "yes" 
        } else { 
            set txtPoX 350.944 ; set txtCen [expr $txtPoX+$bcl] ; set txtMir "no" 
        }
        set txtPoY 524.540 
    } else {
        if { [string match "NO_MIRROR" $ls] } { 
            set txtPoX [expr 461.944+41.656] ; set txtCen [expr $txtPoX-$bcl] ; set txtMir "yes" 
        } else { 
            set txtPoX 461.944 ; set txtCen [expr $txtPoX+$bcl] ; set txtMir "no" 
        }
        set txtPoY 631.540 
    }
    
    set para "add_text,attributes=no,type=barcode,x=$txtPoX,y=$txtPoY,text=$txtSou, x_size=5.08,y_size=5.08,w_factor=2,polarity=positive,angle=0,mirror=$txtMir, fontname=standard,bar_type=UPC39,bar_char_set=full_ascii,bar_checksum=no, bar_background=yes,bar_add_string=yes,bar_add_string_pos=top,bar_width=0.2032,bar_height=10.15,ver=1"
    COM $para
} else {
    tk_messageBox -message " 옵션을 확인 하여 주세요 !! "
}
OPTION_CLEAR
return $cnt
}
#############################################################################
## Procedure:  pSub_Create

proc ::pSub_Create {} {
global widget INFO FORM 

if { [string trim $FORM(EDITOR)] == "" } { tk_messageBox -message " Editor 담당자가 입력되지 않았습니다. 확인바랍니다. ?? " ; return 0 }
if { [string trim $FORM(TARREV)] == "" } { tk_messageBox -message " REV 입력되지 않았습니다. 확인바랍니다. ?? " ; return 0 }

set prn [regsub "k" [lindex [split $INFO(SUB) +] 0] ""]
set prn_len [expr [string length $prn] - 1]

set fstname [string range $prn 0 2]
set midname [string range $prn 3 [expr $prn_len - 1]]
set lstname [string range $prn $prn_len $prn_len ]
set prnname "${fstname}-${midname}-${lstname}-${FORM(TARREV)}"
set jaguri  "${midname}${lstname}${FORM(TARREV)}"
set newname "k${fstname}${midname}${lstname}$FORM(TARREV)"

set stp ${prn}_pnl
set lyrList [Tablelist_MATRIX getcolumns 0]
set tarstp ""
set nowdate [clock format [clock scan now] -format %Y-%m-%d]

COM set_attribute,type=job,job=$INFO(SUB),name1=,name2=,name3=,attribute=operator,value=$FORM(EDITOR),units=inch
COM set_attribute,type=job,job=$INFO(SUB),name1=,name2=,name3=,attribute=work_date,value=$nowdate,units=inch
COM set_attribute,type=job,job=$INFO(SUB),name1=,name2=,name3=,attribute=mana,value=$prnname,units=inch
COM set_attribute,type=job,job=$INFO(SUB),name1=,name2=,name3=,attribute=mana1,value=$jaguri,units=inch

DO_INFO -t matrix -e $INFO(SUB)/matrix,units=mm

OPEN_JOB_STEP_OPTION_CLEAR $INFO(SUB) $stp
foreach LYR $gROWname {if { [lsearch $lyrList $LYR] == -1 && $LYR != "" } { COM delete_layer,layer=$LYR } }

foreach rowdata $FORM(Table_MATRIX) {
    set lyr [lindex $rowdata 0] ; set xs [lindex $rowdata 3] ; set ys [lindex $rowdata 4]
    pSubrev_Stretch_Modify $INFO(SUB) $stp $lyr $xs $ys
    pSubrev_Jaguri_Modify $INFO(SUB) $stp $lyr "1.2" "1.0" "2.6" "2.3" [string length $midname]
}

#OPEN_JOB_STEP_OPTION_CLEAR $INFO(SUB) $stp
foreach rowdata $FORM(Table_MATRIX) {
    set lyr [lindex $rowdata 0] ; set xs [lindex $rowdata 3] ; set ys [lindex $rowdata 4]
    DO_INFO -t layer -e $INFO(SUB)/$stp/$lyr -d LPD    
    COM units,type=inch
    COM "image_open_elpd,job=$INFO(SUB),step=$stp,layer=$lyr,units=inch,device_type=EITHER TYPE"
    COM "image_set_elpd2,job=$INFO(SUB),step=$stp,layer=$lyr,device_type=EITHER TYPE,polarity=$gLPDpolarity,speed=0,xstretch=$xs,ystretch=$ys,xshift=0,yshift=0,xmirror=0,ymirror=0,copper_area=0,xcenter=0,ycenter=0,plot_kind1=56,plot_kind2=56,minvec=0,advec=0,minflash=0,adflash=0,conductors1=0,conductors2=0,conductors3=0,conductors4=0,conductors5=0,media=first,smoothing=smooth,swap_axes=$gLPDswap_axes,define_ext_lpd=yes,resolution_value=$gLPDres_value,resolution_units=$gLPDres_units,quality=auto,enlarge_polarity=both,enlarge_other=leave_as_is,enlarge_panel=no,enlarge_contours_by=0,overlap=no,enlarge_image_symbols=no,enlarge_0_vecs=no,enlarge_symbols=none,enlarge_symbols_by=0,symbol_name1=,enlarge_by1=0,symbol_name2=,enlarge_by2=0,symbol_name3=,enlarge_by3=0,symbol_name4=,enlarge_by4=0,symbol_name5=,enlarge_by5=0,symbol_name6=,enlarge_by6=0,symbol_name7=,enlarge_by7=0,symbol_name8=,enlarge_by8=0,symbol_name9=,enlarge_by9=0,symbol_name10=,enlarge_by10=0"
    COM  image_close_elpd    
}

COM editor_page_close

foreach stn $gCOLstep_name {
    if { $stn == "" } { continue }
    set tarstp ${prn}${FORM(TARREV)}[string trimleft $stn $prn]
    if { [string match $prn* $stn] } { COM rename_entity,job=$INFO(SUB),is_fw=no,type=step,fw_type=form,name=$stn,new_name=$tarstp }
}

COM save_job,job=$INFO(SUB),override=no
COM check_inout,mode=in,type=job,job=$INFO(SUB)
COM close_job,job=$INFO(SUB)
COM close_form,job=$INFO(SUB)
COM close_flow,job=$INFO(SUB)
COM rename_entity,job=,is_fw=no,type=job,fw_type=form,name=$INFO(SUB),new_name=$newname

init_value
NoteBook1 raise [NoteBook1 page 0]
pButton_JOBLIST_RELOAD

tk_messageBox -message "$newname 으로 DATA  생성이 완료되었습니다. "

return
}
#############################################################################
## Procedure:  pFeatureFile_Text_Control

proc ::pFeatureFile_Text_Control {job stp lyr opt args} {
# 0 : 0 degrees, no mirror ,1 : 90 degrees, no mirror ,2 : 180 degrees, no mirror ,3 : 270 degrees, no mirror ,4 : 0 degrees, mirror in X axis ,  
# 5 : 90 degrees, mirror in X axis, 6 : 180 degrees, mirror in X axis ,7 : 270 degrees, mirror in X axis  
# line width to factor cal - 1unit == 12mil ex) micron 1270um width saving to -> 1270 / 304.8 == 4.166666
# save and change factor - Text Adding - width - Info manager Feature to change equl

global INFO
set PATH $INFO(DBPATH) ; set ORG_PATH $INFO(ORPATH)
set logkey [clock scan seconds]
after 1000
set DATA(SYM_LIST) "" ; set DATA(AT1_LIST) "" ; set DATA(AT2_LIST) "" ; set DATA(FEAT_LIST) ""
set AT "" ; set AT1 "" ; set AT2 "" ; set txt(Sou) ""
set inc 0.00003937 ; set wfa 0.00328084
#set inc 25400 ; set wfa 304.8
set cnt 0

if { [llength $args] == 0 } { puts " Not enough agruments !! " ; exit }
 
foreach {item value} $args { 
    if { [lsearch "Xle Yle Wid" $item] != -1 } { 
        set txt($item) [expr $value*$inc]
    } else {
        set txt($item) $value 
    }
    lappend cValue $item
}

puts [parray txt]

if { [file exists "$PATH/$job/steps/$stp/layers/$lyr/features.Z"] } {
     exec gzip -d "$PATH/$job/steps/$stp/layers/$lyr/features.Z"
}

file copy   "$PATH/$job/steps/$stp/layers/$lyr/features" "$ORG_PATH/${job}_${stp}_${lyr}_${logkey}_o"
file rename "$PATH/$job/steps/$stp/layers/$lyr/features" "$PATH/$job/steps/$stp/layers/$lyr/features+"

set f [open "$PATH/$job/steps/$stp/layers/$lyr/features+" r ]

set data [regsub -all "{}" [split [read $f] "\n"] ""]

close $f

foreach row $data {
    if { [string match $* $row] } {
        lappend DATA(SYM_LIST) [lindex $row 1]
    } elseif { [string match @* $row] } {
        lappend DATA(AT1_LIST) [lindex $row 1]
    } elseif { [string match &* $row] } {
        lappend DATA(AT2_LIST) [lindex $row 1]
    } elseif { !($row == "" || [string match #* $row]) } {
        lappend DATA(FEAT_LIST) $row
    }
}


if { $opt == "m" || $opt == "f" } {
    if { [string toupper $txt(attb)] != "N"  } {
        if { [string first \\ $txt(attr)] != -1 } { 
            if { [regsub -all {[0-1]} $txt(attr) ""] != "" } { puts "bad option !!" ; exit }
            set attlist [split $txt(attr) \\]
            foreach att $attrlist {
                if { [lsearch $DATA(AT1_LIST) $att] != -1 } { lappend AT1 [regsub -all {\D} [lindex [lsearch $DATA(AT1_LIST) $att] 0] ""] }
                if { [lsearch $DATA(AT2_LIST) $att] != -1 } { lappend AT2 [regsub -all {\D} [lindex [lsearch $DATA(AT2_LIST) $att] 0] ""] }
            }
        } else {
            if { [lsearch $DATA(AT1_LIST) $txt(attr)] != -1 } { lappend AT1 [regsub -all {\D} [lindex [lsearch $DATA(AT1_LIST) $txt(attr)] 0] ""] }
            if { [lsearch $DATA(AT2_LIST) $txt(attr)] != -1 } { lappend AT2 [regsub -all {\D} [lindex [lsearch $DATA(AT2_LIST) $txt(attr)] 0] ""] }
        }
        set AT [concat $AT1 $AT2]
    }
    
    set rcnt 0
    foreach line $DATA(FEAT_LIST) {
        if { [string match "T*" $line] && [string match "*'$txt(Sou)'*" $line] } {
            if { [string toupper $txt(attb)] != "N"  } {
                if { $txt(attb) == 1 } { set txtatrc 1 } else { set txtatrc 0 }
                foreach at $AT {
                    if { $txt(attb) == 1 } {
                        set atl [split [lindex [split [join $line ""] ";"] 1] ,]
                        if {[lsearch $atl $at] != -1 } { set txtatrc [expr $txtatrc*1] } else { set txtatrc [expr $txtatrc*0] }
                    } else {
                        if {[lsearch $atl $at] != -1 } { set txtatrc [expr $txtatrc+1] } else { set txtatrc [expr $txtatrc+0] } 
                    }
                }
                if { $txtatrc == 0 } { continue }                
            }                                
            incr cnt
            if { $opt == "f" } { continue }
            if { ![info exists txt(Tar)] } { set txt(Tar) "'$txt(Sou)'" }
            
            foreach { item ino } { PoX 1 PoY 2 Typ 3 Pol 4 AMT 5 Xle 6 Yle 7 Wid 8 } {
                if { [lsearch $cValue $item] == -1 } { set txt($item) [lindex $line $ino] }
            }
                        
            if { [lsearch -glob $line "1;*"] != -1 } {
                set txt(Atr) [lindex $line [lsearch -glob $line "1;*"]]
            } else {
                set txt(Atr) ""
            }
            puts $txt(Tar)
#            puts "T $txt(PoX) $txt(PoY) $txt(Typ) $txt(Pol) $txt(AMT) $txt(Xle) $txt(Yle) $txt(Wid) ${txt(Tar)} $txt(Atr)"
            set DATA(FEAT_LIST) [lreplace $DATA(FEAT_LIST) $rcnt $rcnt "T $txt(PoX) $txt(PoY) $txt(Typ) $txt(Pol) $txt(AMT) $txt(Xle) $txt(Yle) $txt(Wid) '${txt(Tar)}' $txt(Atr)"]
        }
        incr rcnt
    }
} elseif { $opt == "a" } {
    if { [llength $args] < 9 } { puts " Not enough agruments !! " ;; exit }
        set txt(Sou) [lindex $args 0]
        set txt(PoX) [expr [lindex $args 1]*$inc*1000] ; set txt(PoY) [expr [lindex $args 2]*$inc*1000]
        set txt(Typ) [lindex $args 3] ; set txt(Pol) [lindex $args 4]
        set txt(AMT) [lindex $args 5]
        set txt(Xle) [expr [lindex $args 6]*$inc] ; set txt(Yle) [expr [lindex $args 7]*$inc]
        set txt(Wid) [expr [lindex $args 8]*$wfa]


    if { [llength $args] == 9 } {
        set txt(Atr) 1
    } else {
        set txt(Atr) 1;[join [lrange $args 9 [expr [llength $args]+1]] ,]
    }
    
    lappend DATA(FEAT_LIST) "T $txt(PoX) $txt(PoY) $txt(Typ) $txt(Pol) $txt(AMT) $txt(Xle) $txt(Yle) $txt(Wid) '${txt(Sou)}' $txt(Atr)"
    
} else {
  puts  " invailid option !! "
}

set f [open "$PATH/$job/steps/$stp/layers/$lyr/features" w+ ]

foreach var { SYM_LIST AT1_LIST AT2_LIST FEAT_LIST } {
    if {[llength $DATA($var)] < 1} { continue }    
    switch -exact -- $var {
       SYM_LIST {
           puts $f "#"
           puts $f "#Feature symbol names"
           puts $f "#"
           set chk "$"
       }
       AT1_LIST {
           puts $f ""
           puts $f "#"
           puts $f "#Feature attribute names"
           puts $f "#"
           set chk "@"
       }
       AT2_LIST {
           puts $f ""
           puts $f "#"
           puts $f "#Feature attribute text strings"
           puts $f "#"
           set chk "&"
       }
       FEAT_LIST {
           puts $f ""
           puts $f "#"
           puts $f "#Layer features"
           puts $f "#"
       }
    }
    
    set pcnt 0
    foreach line $DATA($var) {
        if { $var != "FEAT_LIST" } {
            puts $f "$chk$pcnt $line" 
            incr pcnt
        } else {
            puts $f $line
        }
    }
}

close $f

file delete "$PATH/$job/steps/$stp/layers/$lyr/features+"

set f [open "$PATH/$job/steps/$stp/layers/$lyr/.features.sum" r ] ; set data [regsub -all "{}" [split [read $f] "\n"] ""] ; close $f
set f [open "$PATH/$job/steps/$stp/layers/$lyr/.features.sum" w ]
puts $f "SIZE=[file size "$PATH/$job/steps/$stp/layers/$lyr/features"]"
set fcnt 0
foreach l $data {
   if { $fcnt == 0 } { incr fcnt ; continue }
   puts $f $l
   incr fcnt
}
close $f
file copy   "$PATH/$job/steps/$stp/layers/$lyr/features" "$ORG_PATH/${job}_${stp}_${lyr}_${logkey}_m"
return $cnt
}
#############################################################################
## Procedure:  pPARA_LPD_IMPORT

proc ::pPARA_LPD_IMPORT {job stp} {
global INFO LPD
if { [array exists LPD] } { array unset LPD }

foreach i [glob -type d $INFO(DBPATH)/$job/steps/$stp/layers/*] {
    set LYR [file tail $i] ; set PATH "${i}/lpd"
    if { [file exists $PATH] } {
        set f [open $PATH r] ; set data [regsub -all "{}" [split [read $f] "\n"] ""] ; close $f
        foreach i $data { 
            set is_f [lindex [split $i "="] 0] ; set is_e [lindex [split $i "="] 1] 
            lappend LPD($is_f) $is_e
            
            if {[lsearch [array names LPD] "INDEX"] == -1 || [lsearch $LPD(INDEX) $is_f] == -1 } {
                lappend LPD(INDEX) $is_f
            }
        }
        lappend LPD(LAYER) $LYR
    } else {
        foreach i $INFO(lpd) {
            set val [string toupper $i]
            if { $val == "PLOT_KIND1" || $val == "PLOT_KIND2" } {
                lappend LPD($val) 56
            } elseif { $val == "RESOLUTION_VALUE" } {
                lappend LPD($val) 0.25
            } elseif { $val == "XSTRETCH" || $val == "YSTRETCH" } {
                lappend LPD($val) 100
            } elseif { [lsearch $INFO(lpd_int) $val] != -1 } {
                lappend LPD($val) 0
            } else {
                lappend LPD($val) ""
            }
        }
        lappend LPD(LAYER) $LYR
    }
}

return
}
#############################################################################
## Procedure:  pPlot

proc ::pPlot {job stp lyr} {
global widget INFO FORM

set d_path "/home/genesis"

foreach row $FORM(LYR_SEL) {

    set lyr [lindex $row 0] ; set pol  [lindex $row 3] ; set xst [lindex $row 4] ; set yst [lindex $row 5] ; set mr  [lindex $row 6] ; set swp [lindex $row 7]
    set cnt  [lindex $row 8] ; set fms [lindex $row 9] ; set xsf [lindex $row 10] ; set ysf [lindex $row 11] ; set mac [string tolower [lindex $row 12]] ; set resol [lindex $row 13] 
    set now_sec [clock scan now]
    
    switch -exact -- $resol {
        8000dpi(0.125mil)     { set rev 0.125   ; set reu "mil" ; set oreu "inch" ; set orev 0.0005  }
        10160dpi(2.5micron)   { set rev 2.5     ; set reu "micron" ; set oreu "mm" ; set orev 0.01   }
        16000dpi(0.0625mil)   { set rev 0.0625  ; set reu "mil" ; set oreu "inch" ; set orev 0.0005  }
        25400dpi(1micron)     { set rev 1       ; set reu "micron" ; set oreu "mm" ; set orev 0.01   }
        32000dpi(0.03125mil)  { set rev 0.03125 ; set reu "mil" ; set oreu "inch" ; set orev 0.0005  }
        40640dpi(0.625micron) { set rev 0.625   ; set reu "micron" ; set oreu "mm" ; set orev 0.01   }
        50800dpi(0.5micron)   { set rev 0.5     ; set reu "micron" ; set oreu "mm" ; set orev 0.01   }
    }

    switch -exact -- $mr {
        XMIRROR   {  set xmr [expr $INFO(X) * ($xst/100) / 2] ; set ymr 0 }
        YMIRROR   {  set xmr 0 ; set ymr [expr $INFO(Y) * ($yst/100) / 2] }
        NO_MIRROR {  set xmr 0 ; set ymr 0 }
    }
    
    OPEN_JOB_STEP_OPTION_CLEAR $INFO(JOB) $INFO(STP)
    COM units,type=inch
    COM "image_open_elpd,job=$INFO(JOB),step=$INFO(STP),layer=$lyr,units=inch,device_type=LP-9"
    COM "image_set_elpd2,job=$INFO(JOB),step=$INFO(STP),layer=$lyr,device_type=LP-9,polarity=$pol,speed=0,xstretch=$xst,ystretch=$yst,xshift=$xsf,yshift=$ysf,xmirror=$xmr,ymirror=0,copper_area=0,xcenter=0,ycenter=0,plot_kind1=56,plot_kind2=56,minvec=0,advec=0,minflash=0,adflash=0,conductors1=0,conductors2=0,conductors3=0,conductors4=0,conductors5=0,media=first,smoothing=smooth,swap_axes=$swp,define_ext_lpd=yes,resolution_value=$rev,resolution_units=$reu,quality=auto,enlarge_polarity=both,enlarge_other=leave_as_is,enlarge_panel=no,enlarge_contours_by=0,overlap=no,enlarge_image_symbols=no,enlarge_0_vecs=no,enlarge_symbols=none,enlarge_symbols_by=0,symbol_name1=,enlarge_by1=0,symbol_name2=,enlarge_by2=0,symbol_name3=,enlarge_by3=0,symbol_name4=,enlarge_by4=0,symbol_name5=,enlarge_by5=0,symbol_name6=,enlarge_by6=0,symbol_name7=,enlarge_by7=0,symbol_name8=,enlarge_by8=0,symbol_name9=,enlarge_by9=0,symbol_name10=,enlarge_by10=0"
    COM  image_close_elpd
    COM "output_layer_reset"
    COM "output_layer_set,layer=$lyr,angle=0,mirror=no,x_scale=1,y_scale=1,comp=0,polarity=positive,setupfile=,setupfiletmp=,line_units=mm,gscl_file=,step_scale=no"    
    COM "output,job=$INFO(JOB),step=$INFO(STP),format=LP-9,dir_path=$d_path,prefix=,suffix=,break_sr=no,break_symbols=no,break_arc=no,scale_mode=all,surface_mode=contour,units=$oreu,x_anchor=0,y_anchor=0,x_offset=0,y_offset=0,line_units=inch,override_online=yes,film_size=$fms,local_copy=no,send_to_plotter=yes,plotter_group=,units_factor=$orev,auto_purge=no,entry_num=5,plot_copies=$cnt,imgmgr_name=$mac,deliver_date=,plot_mode=single" 
    COM editor_page_close

    set f [open "$INFO(LOGPATH)/plot_${INFO(RUNTIME)}" a+ ] ; puts $f "PLOT TIME : [clock format $now_sec -format %y%m%d_%H%M%S]" ; puts $f $row ; close $f
    lappend FORM(Table_LOG) $row
    Tablelist_PLOT delete 0
}
}
#############################################################################
## Procedure:  dd

proc ::dd {} {
global widget FORM INFO LPD

set INFO(STP) $FORM(STP)
set FORM(Table_LAYER) ""

set fms "" ; set pmr "" ; set dmr "" ; set xsf "" ; set ysf "" ; set xlen "" ; set ylen ""

foreach {x y} [pFilm_SIZE_CHK "$INFO(DBPATH)/$INFO(JOB)/steps/$INFO(STP)/profile" ""] { set INFO(X) $x ; set INFO(Y) $y  }
set HLYR [expr $INFO(LCNT)/2]

DO_INFO -t matrix -e $INFO(JOB)/matrix,units=mm
Tablelist_LAYER configure -editstartcommand pTable_Scmd -editendcommand pTable_Ecmd
set row 0

foreach lyr $gROWname con $gROWcontext typ $gROWlayer_type {
    set fms [pFilm_SIZE_CHK "$INFO(DBPATH)/$INFO(JOB)/steps/$INFO(STP)/profile" "fms"]
    if { $lyr == "" } { continue }
    
    set match 0
    foreach i $INFO(PLOTLYR) { if { [string match ${i}* $lyr] } { set match 1 ; break } }
    if { ( $con == "misc" && !$match ) || ( $typ == "drill" || $lyr == "rout" ) || [string match *.gbr $lyr] } { continue }
    
    set LPDNO [lsearch $LPD(LAYER) $lyr]
    
    if { $LPDNO == -1 } { lappend FORM(Table_LAYER) [list $lyr $typ "POSITIVE" 100.000 100.000 "NO_MIRROR" "NO_SWAP" 1 $fms 0 0 "LP9" "8000dpi(0.125mil)" ] ; incr row ; continue}
    
    set xt [lindex $LPD(XSTRETCH) $LPDNO] ; set yt [lindex $LPD(YSTRETCH) $LPDNO]
     
    if { $FORM(PLOTMODE) } { set xstr [format "%3.3f" $xt] ; set ystr [format "%3.3f" $yt] } else { set xstr $FORM(LABEL_XSTR) ; set ystr $FORM(LABEL_YSTR) }


    set pol  [lindex $LPD(POLARITY) $LPDNO] ; set swp [lindex $LPD(SWAP_AXES) $LPDNO]
    set xm [lindex $LPD(XMIRROR) $LPDNO] ; set ym [lindex $LPD(YMIRROR) $LPDNO]
    set resol_v [lindex $LPD(RESOLUTION_VALUE) $LPDNO] ; set resol_u [lindex $LPD(RESOLUTION_UNITS) $LPDNO]
    
    if { $resol_u == "MIL" } {
        switch $resol_v {
           0.125   { set rev "8000dpi(0.125mil)"    }
           0.0625  { set rev "16000dpi(0.0625mil)"  }
           0.03125 { set rev "32000dpi(0.03125mil)" }
           default { set rev "10160dpi(2.5micron)" }
        }
    } else {
        switch $resol_v {
           2.5   { set rev "10160dpi(2.5micron)"   }
           1     { set rev "25400dpi(1micron)"     }ddddddddd
           0.625 { set rev "40640dpi(0.625micron)" }
           0.5   { set rev "50800dpi(0.5micron)"   }
           default { set rev "10160dpi(2.5micron)" }
        }
    }
       
    if { $xm != 0 } { set pmr "XMIRROR" } elseif { $ym != 0 } { set pmr "YMIRROR" } else { set pmr "NO_MIRROR" }

    if { ( $typ == "signal" || $typ == "power_ground" ) && $con == "board" } {
        if { $lyr > $INFO(COREs) && $lyr < $INFO(COREe) } {
            if { [expr $INFO(COREs) % 2] } {
                if { [expr $lyr % 2]  } {  set dmr "XMIRROR" } else { set dmr "NO_MIRROR"  }
            } else {
                if { [expr $lyr % 2]  } { set dmr "NO_MIRROR"  } else { set dmr "XMIRROR" }
            }
        } else {
            if { $lyr <= $HLYR } { set dmr "XMIRROR"  } else { set dmr "NO_MIRROR" }
        }
        
        if { $rev == "8000dpi(0.125mil)" || $rev != "16000dpi(0.0625mil)" } { set rev "10160dpi(2.5micron)" }
        
    } else {
      switch -exact -- $lyr {
          tm    { set dmr  "NO_MIRROR" ; set rev "8000dpi(0.125mil)" }
          bm    { set dmr  "XMIRROR"   ; set rev "8000dpi(0.125mil)" }
          smc   { set dmr  "XMIRROR"   ; set rev "8000dpi(0.125mil)" }
          sms   { set dmr  "NO_MIRROR" ; set rev "8000dpi(0.125mil)" }
          ospc  { set dmr  "NO_MIRROR" ; set rev "8000dpi(0.125mil)" }
          osps  { set dmr  "XMIRROR"   ; set rev "8000dpi(0.125mil)" }
          auresistc { set dmr  "XMIRROR"   ; set rev "8000dpi(0.125mil)" }
          auresists { set dmr  "NO_MIRROR" ; set rev "8000dpi(0.125mil)" }
          chamferresistc { set dmr  "NO_MIRROR" ; set rev "8000dpi(0.125mil)" }
          chamferresists { set dmr  "XMIRROR" ; set rev "8000dpi(0.125mil)" }
          silkc { set dmr  "NO_MIRROR" ; set rev "8000dpi(0.125mil)" }
          silks { set dmr  "XMIRROR" ; set rev "8000dpi(0.125mil)" }
          w-etchc { set dmr "XMIRROR" ; set rev "10160dpi(2.5micron)" }
          w-etchs { set dmr "NO_MIRROR" ; set rev "10160dpi(2.5micron)" }
          w-etch_c { set dmr "XMIRROR" ; set rev "10160dpi(2.5micron)" }
          w-etch_s { set dmr "NO_MIRROR" ; set rev "10160dpi(2.5micron)" }
          default {
                   if { [string match plug* $lyr ] } {
                       set ft [string trimleft [lindex [split $lyr -] 0] "plug"]
                       set et [lindex [split $lyr -] 1]
                       set rev "8000dpi(0.125mil)"
                       if { $ft < $et } { set dmr "NO_MIRROR" } else { set dmr "XMIRROR" }
                   } elseif { [string match con* $lyr ] } {
                       set rev "10160dpi(2.5micron)"
                       if { [regsub -all {\D} $lyr ""] > $HLYR } { set dmr "NO_MIRROR" } else { set dmr "XMIRROR" }
                   } elseif { [string match w-etch* $lyr ] } {
                       set rev "8000dpi(0.125mil)"
                       if { [regsub -all {\D} $lyr ""] > $HLYR } { set dmr "NO_MIRROR" } else { set dmr "XMIRROR" }
                   } elseif { [string match etch* $lyr ] } {
                       set rev "8000dpi(0.125mil)"
                       if { [regsub -all {\D} $lyr ""] > $HLYR } { set dmr "NO_MIRROR" } else { set dmr "XMIRROR" }
                   }
          }
      }
    }

    if { [lsearch $INFO(JPLIST) $lyr* ] == -1 && $fms == "24x20" }  { set fms "24x28" }

    set mr $dmr
       
    if { $fms == "24x20" } { set swp "SWAP" ; if { $mr == "NO_MIRROR" } { set mr "XMIRROR" } else { set mr "NO_MIRROR" } } 
    
    set fx  [expr round([expr $INFO(X)*25.4])] ; set fy  [expr round([expr $INFO(Y)*25.4])]
    
    if { $lyr == "smc" || $lyr == "sms" } {
        switch -exact -- "${fx}x${fy}" {
            352x512 { set xsf 1.226 ; set ysf 1.593 }
            352x522 { set xsf 1.226 ; set ysf 1.693 }
            418x512 { set xsf 0.910 ; set ysf 1.593 }
            418x522 { set xsf 0.910 ; set ysf 1.693 }
            default {
            if { $fms == "24x28" } { set xsf [expr ((24-$INFO(X))/2)-1] ; set ysf [expr ((28-$INFO(Y))/2)-(7/25.4)] } else { set xsf [expr ((24-$INFO(X))/2)-1-(5/25.4)] ; set ysf [expr ((20-$INFO(Y))/2)-(7/25.4)] }
            }
        }
    } else {
       if { $fms == "24x28" } { set xsf [expr ((24-$INFO(X))/2)-1] ; set ysf [expr ((28-$INFO(Y))/2)-(7/25.4)] } else { set xsf [expr ((24-$INFO(X))/2)-1-(5/25.4)] ; set ysf [expr ((20-$INFO(Y))/2)-(7/25.4)] }
    }
    
    if { $FORM(PLOTMODE) == 1 } {
        lappend FORM(Table_LAYER) [list $lyr $typ $pol $xstr $ystr $mr $swp 1 $fms $xsf $ysf "LP9" $rev ]
    } else {
        if { [lsearch $INFO(PLOTLYR) $lyr] != -1 } { lappend FORM(Table_LAYER) [list $lyr $typ $pol $xstr $ystr $mr $swp 1 $fms $xsf $ysf "LP9" $rev ] } else { continue }
    }
    
    if { $con == "board" } {
        switch $typ {
          silk_screen  { Tablelist_LAYER rowconfigure $row -background white    }
          solder_mask  { Tablelist_LAYER rowconfigure $row -background green    }
          signal       { Tablelist_LAYER rowconfigure $row -background yellow   }
          power_ground { Tablelist_LAYER rowconfigure $row -background tomato   }
          drill        { Tablelist_LAYER rowconfigure $row -background darkgray }
          rout         { Tablelist_LAYER rowconfigure $row -background gray     }
        }
    } else {
        Tablelist_LAYER rowconfigure $row -background darkblue -fg white
    }
    incr row
}

tk_messageBox -message " 중요 !!! 파라미터 값 확인 후 진행하시기 바랍니다. !!! "
}
#############################################################################
## Procedure:  pXY_SHIFT

proc ::pXY_SHIFT {x y unit ft outfs} {
set inc 0.0393700787402

if { [regsub -all {[0-9]|\.} $x$y ""] != ""  } { puts " Not is Numeric !! " ; exit }
if { $unit == "mm" } {
    set fx  $x ; set fy  $y ; set ix [expr $x*$inc] ; set iy [expr $y*$inc]
} elseif { $unit == "inch" } {
    set fx [expr round($x*25.4)] ; set fy  [expr round($y*25.4)]
    set ix $x ; set iy $y 
} else {
    puts "Bad Option !! ( mm or inch )"
    exit
}
 
if { $ft == "sr" } {
    switch -exact -- "${fx}x${fy}" {
       352x512 { set xsf 1.226 ; set ysf 1.593 }
       352x522 { set xsf 1.226 ; set ysf 1.693 }
       418x512 { set xsf 0.910 ; set ysf 1.593 }
       418x522 { set xsf 0.910 ; set ysf 1.693 }
       default {
                if { $outfs == "24x28" } { 
                    set xsf [expr ((24-$ix)*0.5)-1] ; set ysf [expr ((28-$iy)*0.5)-(7*$inc)] 
                } else { 
                   set xsf [expr ((24-$ix)*0.5)-1-(5*$inc)] ; set ysf [expr ((20-$iy)*0.5)-(7*$inc)] 
                }
       }
    }
} else {
    if { $outfs == "24x28" } { 
        set xsf [expr ((24-$ix)*0.5)-1] ; set ysf [expr ((28-$iy)*0.5)-(7*$inc)] 
    } else { 
        set xsf [expr ((24-$ix)*0.5)-1-(5*$inc)] ; set ysf [expr ((20-$iy)*0.5)-(7*$inc)] 
    }
}

return [list $xsf $ysf]
}
#############################################################################
## Procedure:  pFilmSize_Chk

proc ::pFilmSize_Chk {path} {
set f [ open $path { RDONLY } ]
while { ![eof $f] } { gets $f l ; if { [string range $l 0 1] == "OS" } { lappend xl [lindex [split $l " "] 1] ; lappend yl [lindex [split $l " "] 2] } }
close $f

set xmin [lindex [lsort -real $xl] 0]
set ymin [lindex [lsort -real $yl] 0]
set xmax [lindex [lsort -real -decreasing $xl] 0]
set ymax [lindex [lsort -real -decreasing $yl] 0]
set xlen [expr ($xmax - $xmin)*25.4]
set ylen [expr ($ymax - $ymin)*25.4]

return [list $xlen $ylen]
}
#############################################################################
## Procedure:  pText_MODIFY

proc ::pText_MODIFY {job stp lyr opt args} {

}
#############################################################################
## Procedure:  pBACK_GROUND

proc ::pBACK_GROUND {} {
global INFO
if { ![file exists "/autoPlot/list.csv" ] } { puts "Output List(csv) not found !! " ; exit }
source  "/autoPlot/list.csv"

if { [file isdirectory $INFO(ORPATH)] != 1 } { file mkdir $INFO(ORPATH) }
    
#                        0        1    2        3         4     5     6       7        8        9              10       11    12
#lappend LIST(PLOT) { PRDT       rev  M/S   TOOL Name    LYR  Xstr  Ystr   MES_Xstr MES_Ystr Date_Code_Type Date_Code Dynamic 2D}
#lappend LIST(PLOT) { "k8so047m" "mc" "M"  "TOOL Name"  "1/10" "100" "100" "100.02" "100.015" "YYWW"          "2001"    "Y"    "Y"}
#lappend LIST(PLOT) { "k8so047m" "mb" "S"  "TOOL Name"  "3/4" "100" "100" "100.02" "100.015" "YYWW-xx"       "2001-01" "N"    "N"}

foreach item $LIST(PLOT) {
   
  # Temporary Name  & Info Create
    set xy ""
    set key [clock scan seconds] ; set nowdate [clock format [clock scan now] -format %Y-%m-%d]
    set ojob [lindex $item 0] ; set tjob "[lindex $item 0]+tjwc_$key"
    set prn [regsub "k" [lindex [split $ojob +] 0] ""]
    set prn_len [expr [string length $prn] - 1]
        
    set fstname [string range $prn 0 2]
    set midname [string range $prn 3 [expr $prn_len - 1]]
    set lstname [string range $prn $prn_len $prn_len ]
        
    set rev [string trimleft [lindex $item 1] $lstname] ; set pro [lindex $item 3]        
        
    set prnname "${fstname}-${midname}-${lstname}-$rev"
    set jaguri  "${midname}${lstname}$rev"

    set stp ${prn}_pnl
        
    set lt  [lindex [split [lindex $item 4] /] 0] ; set lb  [lindex [split [lindex $item 4] /] 1]
    set xstr [lindex $item 5] ; set ystr [lindex $item 6]
    set mxstr [lindex $item 7] ; set mystr [lindex $item 8]
    set date_type [lindex $item 9] ; set date_code [lindex $item 10]
        
    COM copy_entity,type=job,source_job=,source_name=${ojob},dest_job=,dest_name=${tjob},dest_database=,remove_from_sr=yes

    OPEN_JOB $tjob    
    
    # Unused Layer Delete
    DO_INFO -t matrix -e $tjob/matrix, units=mm       
    set row 1
    foreach  name $gROWname {
        if { $name == $lb || $name == $lt } { incr row ; continue }
        COM matrix_delete_row,job=${tjob},matrix=matrix,row=$row
    }
    
    # Attribute modify = Product no    
    COM set_attribute,type=job,job=$tjob,name1=,name2=,name3=,attribute=operator,value=autoplot,units=inch
    COM set_attribute,type=job,job=$tjob,name1=,name2=,name3=,attribute=work_date,value=$nowdate,units=inch
    COM set_attribute,type=job,job=$tjob,name1=,name2=,name3=,attribute=mana,value=$prnname,units=inch
    COM set_attribute,type=job,job=$tjob,name1=,name2=,name3=,attribute=mana1,value=$jaguri,units=inch
    
    SAVE_JOB $tjob
    CLOSE_JOB $tjob
    

    pPARA_LPD_IMPORT $tjob $stp
    set xy [pFilmSize_Chk "$INFO(DBPATH)/$tjob/steps/$stp/profile" ]

    foreach lstp $gCOLstep_name {
        foreach ly " $lt $lb " {
            set DATEChk [pFeatureFile_Text_Control $tjob $lstp $ly f attb Y attr "" Sou $date_type]
            if { $DATEChk > 0 } {
                puts "$lstp / $ly - $date_type / $date_code"
                puts [pFeatureFile_Text_Control $tjob $lstp $ly m attb Y attr "" Sou $date_type Tar $date_code]
            } else {
                puts "$lstp / $ly - $date_type / $date_code - Not Found "
            }
            
            if { ![string match *_pnl $lstp] } { continue }
            set stChk   [pFeatureFile_Text_Control $tjob $lstp $ly f attb Y attr "" Sou "X 100.000 Y 100.000"]
            if { $stChk > 0 } {
                puts "$lt : X $mxstr Y $mystr"
                puts [pFeatureFile_Text_Control $tjob $lstp $ly m attb Y attr "" Sou "X 100.000 Y 100.000" Tar "X $mxstr Y $mystr"]
            } else {
                puts "$lt : X $mxstr Y $mystr - Not Found"
            }
        }
    }

    pPARA_LPD_OUTPUT $tjob $stp 1
      
    set shiftxy [pXY_SHIFT [expr round([lindex $xy 0])] [expr round([lindex $xy 1])] "mm" signal "24x28"]
    
 #   if { [string length $midname] == 3 } {
 #       puts [pFeatureFile_Text_Control $tjob $stp 2 m attb 1 attr "" Sou "\$\$mana1" Xle [lindex $INFO(JAGURI_SZ) 2] ]
 #       puts [pFeatureFile_Text_Control $tjob $stp 2 m attb 1 attr "elco.stk1" Sou "\$\$mana1"  Xle [lindex $INFO(JAGURI_SZ) 0] ]
 #   } else {
 #       puts [pFeatureFile_Text_Control $tjob $stp 2 m attb 1 attr "" Sou "\$\$mana1" Xle [lindex $INFO(JAGURI_SZ) 3] ]
#        puts [pFeatureFile_Text_Control $tjob $stp 2 m atbb 1 attr "elco.stk1" Sou "\$\$mana1"  Xle [lindex $INFO(JAGURI_SZ) 1] ]
#    }

#    COM delete_entity,job=,type=job,name=$tjob
    exit        
}
#    attb attr org
#    set INFO(JAGURI_SZ)  { "1200" "1000" "2600" "2300" }    
#    pPARA_LPD_MODIFY $INFO(DBPATH) $FORM(JOB) $FORM(STP) 3 100.03 100.025 
#    pFeatureFile_Text_Control $INFO(DBPATH) $FORM(JOB) $FORM(STP) 3 m "PPP" "PPJ"
#    pFeatureFile_Text_Control $INFO(DBPATH) $FORM(JOB) $FORM(STP) 3 m "PPSS" "PPJJ"
#    set DATA(FEAT_LIST) [lreplace $DATA(FEAT_LIST) $rcnt $rcnt "T $txtPoX $txtPoY $txtTyp $txtPol $txtAMT $txtXle $txtYle $txtWid '${txtTar}' 1${txtAtr}"]
}
#############################################################################
## Procedure:  pPARA_LPD_OUTPUT

proc ::pPARA_LPD_OUTPUT {job stp lyr} {
global INFO LPD
set PATH $INFO(DBPATH) ; set ORG_PATH $INFO(ORPATH)

#puts [parray LPD]

set logkey [clock scan seconds]
after 1000

file copy   "$PATH/$job/steps/$stp/layers/$lyr/lpd" "$ORG_PATH/${job}_${stp}_${lyr}_LPD_${logkey}_o"
file delete "$PATH/$job/steps/$stp/layers/$lyr/lpd"
file delete "$PATH/$job/steps/$stp/layers/$lyr/lpd_multiple"

set f [open "$PATH/$job/steps/$stp/layers/$lyr/lpd" w ]
set f1 [open "$PATH/$job/steps/$stp/layers/$lyr/lpd_multiple" w ]

puts $f1 "LPD {"
foreach item $LPD(INDEX) {
    puts $f  "$item=[lindex $LPD($item) [lsearch $LPD(LAYER) $lyr]]"
    puts $f1 "    $item=[lindex $LPD($item) [lsearch $LPD(LAYER) $lyr]]"
}

puts $f1 "}"
close $f ; close $f1

foreach fn { lpd lpd_multiple } {
    set f [open "$PATH/$job/steps/$stp/layers/$lyr/.${fn}.sum" r ] ; set data [regsub -all "{}" [split [read $f] "\n"] ""] ; close $f
    set f [open "$PATH/$job/steps/$stp/layers/$lyr/.${fn}.sum" w ]
    puts $f "SIZE=[file size "$PATH/$job/steps/$stp/layers/$lyr/${fn}"]"
    set fcnt 0
    foreach l $data {
        if { $fcnt == 0 } { incr fcnt ; continue }
        puts $f $l
        incr fcnt
    }
    close $f
    file copy   "$PATH/$job/steps/$stp/layers/$lyr/${fn}" "$ORG_PATH/${job}_${stp}_${lyr}_${fn}_${logkey}_m"
}

return
}

#############################################################################
## Initialization Procedure:  init

proc ::init {argc argv} {
tablelist::addBWidgetComboBox
}

init $argc $argv

#################################
# VTCL GENERATED GUI PROCEDURES
#

proc vTclWindow. {base} {
    if {$base == ""} {
        set base .
    }
    ###################
    # CREATING WIDGETS
    ###################
    wm focusmodel $top passive
    wm geometry $top 1x1+0+0; update
    wm maxsize $top 3825 1050
    wm minsize $top 1 1
    wm overrideredirect $top 0
    wm resizable $top 1 1
    wm withdraw $top
    wm title $top "vtcl.tcl"
    bindtags $top "$top Vtcl.tcl all"
    vTcl:FireEvent $top <<Create>>
    wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"

    ###################
    # SETTING GEOMETRY
    ###################

    vTcl:FireEvent $base <<Ready>>
}

proc vTclWindow.top66 {base} {
    if {$base == ""} {
        set base .top66
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    set top $base
    ###################
    # CREATING WIDGETS
    ###################
    vTcl:toplevel $top -class Toplevel \
        -highlightcolor black 
    wm withdraw $top
    wm focusmodel $top passive
    wm geometry $top 1424x720+239+174; update
    wm maxsize $top 1905 987
    wm minsize $top 1 1
    wm overrideredirect $top 0
    wm resizable $top 1 1
    wm title $top "OUTPUT TOOL"
    vTcl:DefineAlias "$top" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1
    bindtags $top "$top Toplevel all _TopLevel"
    vTcl:FireEvent $top <<Create>>
    wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"

    labelframe $top.lab69 \
        -foreground #0000ff -text {JOB INFO} -height 75 -highlightcolor black \
        -width 125 
    vTcl:DefineAlias "$top.lab69" "Labelframe2" vTcl:WidgetProc "Toplevel1" 1
    set site_3_0 $top.lab69
    label $site_3_0.lab72 \
        -activebackground #f9f9f9 -activeforeground black \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text { JOB : } 
    vTcl:DefineAlias "$site_3_0.lab72" "Label1" vTcl:WidgetProc "Toplevel1" 1
    label $site_3_0.lab73 \
        -activebackground #f9f9f9 -activeforeground black \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -textvariable FORM(JOB) -width 20 
    vTcl:DefineAlias "$site_3_0.lab73" "Label2" vTcl:WidgetProc "Toplevel1" 1
    pack $site_3_0.lab72 \
        -in $site_3_0 -anchor center -expand 0 -fill none -side left 
    pack $site_3_0.lab73 \
        -in $site_3_0 -anchor center -expand 0 -fill none -side left 
    labelframe $top.lab67 \
        -foreground black -text RUN -height 75 -highlightcolor black \
        -width 125 
    vTcl:DefineAlias "$top.lab67" "Labelframe1" vTcl:WidgetProc "Toplevel1" 1
    set site_3_0 $top.lab67
    frame $site_3_0.cpd86 \
        -borderwidth 2 -height 75 -highlightcolor black -width 125 
    vTcl:DefineAlias "$site_3_0.cpd86" "Frame2" vTcl:WidgetProc "Toplevel1" 1
    set site_4_0 $site_3_0.cpd86
    frame $site_4_0.fra76 \
        -borderwidth 2 -height 75 -highlightcolor black -width 125 
    vTcl:DefineAlias "$site_4_0.fra76" "Frame3" vTcl:WidgetProc "Toplevel1" 1
    set site_5_0 $site_4_0.fra76
    button $site_5_0.cpd77 \
        -activebackground #f9f9f9 -activeforeground black -command ptest \
        -disabledforeground #a2a2a2 \
        -font [vTcl:font:getFontFromDescr "-family helvetica -size 20 -weight bold -slant roman -underline 0 -overstrike 0"] \
        -foreground black -highlightcolor black -text OUTPUT 
    vTcl:DefineAlias "$site_5_0.cpd77" "Button1" vTcl:WidgetProc "Toplevel1" 1
    pack $site_5_0.cpd77 \
        -in $site_5_0 -anchor center -expand 0 -fill x -side top 
    labelframe $site_4_0.lab78 \
        -foreground #0000ff -relief flat -text {ERP INFO} -height 75 \
        -highlightcolor black -width 125 
    vTcl:DefineAlias "$site_4_0.lab78" "Labelframe7" vTcl:WidgetProc "Toplevel1" 1
    set site_5_0 $site_4_0.lab78
    label $site_5_0.lab67 \
        -activebackground #f8f8f8 -activeforeground black \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text { REV NO : } 
    vTcl:DefineAlias "$site_5_0.lab67" "Label4" vTcl:WidgetProc "Toplevel1" 1
    entry $site_5_0.cpd68 \
        -background white -disabledforeground #a2a2a2 -foreground black \
        -highlightcolor black -insertbackground black -relief flat \
        -selectbackground #c4c4c4 -selectforeground black -state disabled \
        -textvariable FORM(REVNO) 
    vTcl:DefineAlias "$site_5_0.cpd68" "Entry7" vTcl:WidgetProc "Toplevel1" 1
    label $site_5_0.lab84 \
        -activebackground #f9f9f9 -activeforeground black \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text { FILM NO : } 
    vTcl:DefineAlias "$site_5_0.lab84" "Label9" vTcl:WidgetProc "Toplevel1" 1
    entry $site_5_0.ent85 \
        -background white -disabledforeground #a2a2a2 -foreground black \
        -highlightcolor black -insertbackground black -relief flat \
        -selectbackground #c4c4c4 -selectforeground black -state disabled \
        -textvariable FORM(FILMNO) 
    vTcl:DefineAlias "$site_5_0.ent85" "Entry6" vTcl:WidgetProc "Toplevel1" 1
    label $site_5_0.lab81 \
        -activebackground #f9f9f9 -activeforeground black \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text { DATE TYPE : } 
    vTcl:DefineAlias "$site_5_0.lab81" "Label8" vTcl:WidgetProc "Toplevel1" 1
    entry $site_5_0.ent83 \
        -background white -disabledforeground #a2a2a2 -foreground black \
        -highlightcolor black -insertbackground black -relief flat \
        -selectbackground #c4c4c4 -selectforeground black -state disabled \
        -textvariable FOME(DATETYPE) 
    vTcl:DefineAlias "$site_5_0.ent83" "Entry5" vTcl:WidgetProc "Toplevel1" 1
    label $site_5_0.lab79 \
        -activebackground #f9f9f9 -activeforeground black \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text {DATE CODE : } 
    vTcl:DefineAlias "$site_5_0.lab79" "Label7" vTcl:WidgetProc "Toplevel1" 1
    entry $site_5_0.ent80 \
        -background white -disabledforeground #a2a2a2 -foreground black \
        -highlightcolor black -insertbackground black -relief flat \
        -selectbackground #c4c4c4 -selectforeground black -state disabled \
        -textvariable FORM(DATECODE) 
    vTcl:DefineAlias "$site_5_0.ent80" "Entry4" vTcl:WidgetProc "Toplevel1" 1
    pack $site_5_0.lab67 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.cpd68 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.lab84 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.ent85 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.lab81 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.ent83 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.lab79 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.ent80 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    labelframe $site_4_0.lab90 \
        -foreground #0000ff -relief flat -text {OUTPUT TYPE} -height 75 \
        -highlightcolor black -width 125 
    vTcl:DefineAlias "$site_4_0.lab90" "Labelframe6" vTcl:WidgetProc "Toplevel1" 1
    set site_5_0 $site_4_0.lab90
    checkbutton $site_5_0.che91 \
        -activebackground #f9f9f9 -activeforeground black \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text {  FILM / DI  } -variable FORM(OUT_FD) 
    vTcl:DefineAlias "$site_5_0.che91" "Checkbutton1" vTcl:WidgetProc "Toplevel1" 1
    button $site_5_0.but67 \
        -activebackground #f9f9f9 -activeforeground black \
        -command {pPath_Modify "FORM(DI_PATH)"} -disabledforeground #a2a2a2 \
        -foreground black -highlightcolor black -text /home/genesis/di \
        -textvariable FORM(DI_PATH) 
    vTcl:DefineAlias "$site_5_0.but67" "Button9" vTcl:WidgetProc "Toplevel1" 1
    Separator $site_5_0.sep70 \
        -background #ff0000 
    vTcl:DefineAlias "$site_5_0.sep70" "Separator1" vTcl:WidgetProc "Toplevel1" 1
    bind $site_5_0.sep70 <Destroy> {
        Widget::destroy %W; rename %W {}
    }
    checkbutton $site_5_0.che92 \
        -activebackground #f9f9f9 -activeforeground black \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text {  AOI  } -variable FORM(OUT_AOI) 
    vTcl:DefineAlias "$site_5_0.che92" "Checkbutton2" vTcl:WidgetProc "Toplevel1" 1
    button $site_5_0.but68 \
        -activebackground #f9f9f9 -activeforeground black \
        -command {pPath_Modify "FORM(AOI_PATH)"} -disabledforeground #a2a2a2 \
        -foreground black -highlightcolor black -text /home/genesis/aoi \
        -textvariable FORM(AOI_PATH) 
    vTcl:DefineAlias "$site_5_0.but68" "Button10" vTcl:WidgetProc "Toplevel1" 1
    Separator $site_5_0.sep71 \
        -background #ff0000 
    vTcl:DefineAlias "$site_5_0.sep71" "Separator2" vTcl:WidgetProc "Toplevel1" 1
    bind $site_5_0.sep71 <Destroy> {
        Widget::destroy %W; rename %W {}
    }
    checkbutton $site_5_0.che93 \
        -activebackground #f9f9f9 -activeforeground black \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text {  DRILL  } -variable FORM(OUT_DRL) 
    vTcl:DefineAlias "$site_5_0.che93" "Checkbutton3" vTcl:WidgetProc "Toplevel1" 1
    button $site_5_0.but69 \
        -activebackground #f9f9f9 -activeforeground black \
        -command {pPath_Modify "FORM(DRILL_PATH)"} \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text /home/genesis/drill -textvariable FORM(DRILL_PATH) 
    vTcl:DefineAlias "$site_5_0.but69" "Button11" vTcl:WidgetProc "Toplevel1" 1
    Separator $site_5_0.cpd73 \
        -background #ff0000 
    vTcl:DefineAlias "$site_5_0.cpd73" "Separator3" vTcl:WidgetProc "Toplevel1" 1
    bind $site_5_0.cpd73 <Destroy> {
        Widget::destroy %W; rename %W {}
    }
    checkbutton $site_5_0.che72 \
        -activebackground #f9f9f9 -activeforeground black \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text { P/G} -variable FORM(OUT_PG) 
    vTcl:DefineAlias "$site_5_0.che72" "Checkbutton4" vTcl:WidgetProc "Toplevel1" 1
    button $site_5_0.cpd74 \
        -activebackground #f9f9f9 -activeforeground black \
        -command {pPath_Modify "FORM(PG_PATH)"} -disabledforeground #a2a2a2 \
        -foreground black -highlightcolor black -text /home/genesis/Documents \
        -textvariable FORM(PG_PATH) 
    vTcl:DefineAlias "$site_5_0.cpd74" "Button12" vTcl:WidgetProc "Toplevel1" 1
    Separator $site_5_0.cpd72 \
        -background #ff0000 
    vTcl:DefineAlias "$site_5_0.cpd72" "Separator4" vTcl:WidgetProc "Toplevel1" 1
    bind $site_5_0.cpd72 <Destroy> {
        Widget::destroy %W; rename %W {}
    }
    checkbutton $site_5_0.cpd75 \
        -activebackground #f9f9f9 -activeforeground black \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text { GERBER274x } -variable FORM(OUT_GBR) 
    vTcl:DefineAlias "$site_5_0.cpd75" "Checkbutton5" vTcl:WidgetProc "Toplevel1" 1
    button $site_5_0.cpd76 \
        -activebackground #f9f9f9 -activeforeground black \
        -command {pPath_Modify "FORM(GBR_PATH)"} -disabledforeground #a2a2a2 \
        -foreground black -highlightcolor black -text /home/genesis/pg \
        -textvariable FORM(GBR_PATH) 
    vTcl:DefineAlias "$site_5_0.cpd76" "Button13" vTcl:WidgetProc "Toplevel1" 1
    pack $site_5_0.che91 \
        -in $site_5_0 -anchor center -expand 1 -fill x -side left 
    pack $site_5_0.but67 \
        -in $site_5_0 -anchor center -expand 1 -fill x -side left 
    pack $site_5_0.sep70 \
        -in $site_5_0 -anchor center -expand 0 -fill y -padx 10 -side left 
    pack $site_5_0.che92 \
        -in $site_5_0 -anchor center -expand 1 -fill x -side left 
    pack $site_5_0.but68 \
        -in $site_5_0 -anchor center -expand 1 -fill none -side left 
    pack $site_5_0.sep71 \
        -in $site_5_0 -anchor center -expand 0 -fill y -padx 10 -side left 
    pack $site_5_0.che93 \
        -in $site_5_0 -anchor center -expand 1 -fill x -side left 
    pack $site_5_0.but69 \
        -in $site_5_0 -anchor center -expand 1 -fill x -side left 
    pack $site_5_0.cpd73 \
        -in $site_5_0 -anchor center -expand 0 -fill y -padx 10 -side left 
    pack $site_5_0.che72 \
        -in $site_5_0 -anchor center -expand 1 -fill x -padx 10 -side left 
    pack $site_5_0.cpd74 \
        -in $site_5_0 -anchor center -expand 1 -fill none -side left 
    pack $site_5_0.cpd72 \
        -in $site_5_0 -anchor center -expand 0 -fill y -padx 10 -side left 
    pack $site_5_0.cpd75 \
        -in $site_5_0 -anchor center -expand 1 -fill x -side left 
    pack $site_5_0.cpd76 \
        -in $site_5_0 -anchor center -expand 1 -fill x -side left 
    labelframe $site_4_0.lab69 \
        -foreground black -text {Gerber Option} -height 75 \
        -highlightcolor black -width 125 
    vTcl:DefineAlias "$site_4_0.lab69" "Labelframe8" vTcl:WidgetProc "Toplevel1" 1
    set site_5_0 $site_4_0.lab69
    label $site_5_0.cpd70 \
        -activebackground #f9f9f9 -activeforeground black \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text { STEP : } 
    vTcl:DefineAlias "$site_5_0.cpd70" "Label3" vTcl:WidgetProc "Toplevel1" 1
    ComboBox $site_5_0.cpd71 \
        -disabledforeground #a2a2a2 -entrybg white -foreground black \
        -highlightcolor black -insertbackground black \
        -modifycmd pTable_LYR_REFRESH -postcommand pCOMBO_POST \
        -selectbackground #c4c4c4 -selectforeground black -takefocus 1 \
        -textvariable FORM(STP) 
    vTcl:DefineAlias "$site_5_0.cpd71" "ComboBox_STP1" vTcl:WidgetProc "Toplevel1" 1
    bindtags $site_5_0.cpd71 "$site_5_0.cpd71 BwComboBox $top all"
    pack $site_5_0.cpd70 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.cpd71 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    labelframe $site_4_0.lab88 \
        -foreground #0000ff -relief flat -text Parameter -height 75 \
        -highlightcolor black -width 125 
    vTcl:DefineAlias "$site_4_0.lab88" "Labelframe3" vTcl:WidgetProc "Toplevel1" 1
    set site_5_0 $site_4_0.lab88
    scrollbar $site_5_0.scr92 \
        -activebackground #f9f9f9 -command "$site_5_0.tab90 xview" \
        -highlightcolor black -orient horizontal -troughcolor #c4c4c4 \
        -width 10 
    vTcl:DefineAlias "$site_5_0.scr92" "Scrollbar2" vTcl:WidgetProc "Toplevel1" 1
    scrollbar $site_5_0.scr91 \
        -activebackground #f9f9f9 -command "$site_5_0.tab90 yview" \
        -highlightcolor black -troughcolor #c4c4c4 -width 10 
    vTcl:DefineAlias "$site_5_0.scr91" "Scrollbar1" vTcl:WidgetProc "Toplevel1" 1
    ::tablelist::tablelist $site_5_0.tab90 \
        \
        -columns {8 LAYER center 9 TYPE center 9 POLARITY center 9 FILMSIZE center 8 MIRROR center 5 SWAP center 8 {X SHIFT} center 8 {Y SHIFT} center 8 {X 신축} center 8 {Y 신축} center 12 RESOLUTION center 6 수량 center 6 MAC center 0 CHECK center} \
        -columntitles {LAYER TYPE POLARITY FILMSIZE MIRROR SWAP {X SHIFT} {Y SHIFT} {X 신축} {Y 신축} RESOLUTION 수량 MAC CHECK} \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -labelheight 2 -labelrelief ridge -listvariable FORM(LYR_SEL) \
        -selectbackground #c4c4c4 -selectforeground black \
        -xscrollcommand "$site_5_0.scr92 set" \
        -yscrollcommand "$site_5_0.scr91 set" 
    vTcl:DefineAlias "$site_5_0.tab90" "Tablelist_LYR" vTcl:WidgetProc "Toplevel1" 1
    $site_5_0.tab90 columnconfigure 0 \
        -align center -labelalign center -title LAYER -width 8 
    $site_5_0.tab90 columnconfigure 1 \
        -align center -labelalign center -title TYPE -width 9 
    $site_5_0.tab90 columnconfigure 2 \
        -align center -editable 1 -editwindow ComboBox -labelalign center \
        -name POLARITY -title POLARITY -width 9 
    $site_5_0.tab90 columnconfigure 3 \
        -align center -editable 1 -editwindow ComboBox -labelalign center \
        -name FILMSIZE -title FILMSIZE -width 9 
    $site_5_0.tab90 columnconfigure 4 \
        -align center -editable 1 -editwindow ComboBox -labelalign center \
        -name MIRROR -title MIRROR -width 8 
    $site_5_0.tab90 columnconfigure 5 \
        -align center -editable 1 -editwindow ComboBox -labelalign center \
        -name SWAP -title SWAP -width 5 
    $site_5_0.tab90 columnconfigure 6 \
        -align center -editable 1 -labelalign center -name XSHIFT \
        -title {X SHIFT} -width 8 
    $site_5_0.tab90 columnconfigure 7 \
        -align center -editable 1 -labelalign center -name YSHIFT \
        -title {Y SHIFT} -width 8 
    $site_5_0.tab90 columnconfigure 8 \
        -align center -editable 1 -labelalign center -name XSTRET \
        -title {X 신축} -width 8 
    $site_5_0.tab90 columnconfigure 9 \
        -align center -editable 1 -name YSTRET -title {Y 신축} -width 8 
    $site_5_0.tab90 columnconfigure 10 \
        -align center -editable 1 -editwindow ComboBox -name RESOLUTION \
        -title RESOLUTION -width 12 
    $site_5_0.tab90 columnconfigure 11 \
        -align center -editable 1 -title 수량 -width 6 
    $site_5_0.tab90 columnconfigure 12 \
        -align center -editable 1 -editwindow ComboBox -name MACHINE \
        -title MAC -width 6 
    $site_5_0.tab90 columnconfigure 13 \
        -align center -editable 1 -editwindow checkbutton \
        -formatcommand pEmptyStr -labelalign center -name CHECK -title CHECK 
    bind [$site_5_0.tab90 bodypath] <Configure> {
        set tablelist::W [winfo parent %W]
	tablelist::makeColFontAndTagLists $tablelist::W
	tablelist::adjustElidedTextWhenIdle $tablelist::W
	tablelist::updateColorsWhenIdle $tablelist::W
	tablelist::adjustSepsWhenIdle $tablelist::W
	tablelist::updateVScrlbarWhenIdle $tablelist::W
    }
    pack $site_5_0.scr92 \
        -in $site_5_0 -anchor center -expand 0 -fill x -side bottom 
    pack $site_5_0.scr91 \
        -in $site_5_0 -anchor center -expand 0 -fill y -side right 
    pack $site_5_0.tab90 \
        -in $site_5_0 -anchor center -expand 1 -fill both -side top 
    labelframe $site_4_0.lab89 \
        -foreground #0000ff -relief flat -text Select -height 75 \
        -highlightcolor black -width 125 
    vTcl:DefineAlias "$site_4_0.lab89" "Labelframe4" vTcl:WidgetProc "Toplevel1" 1
    set site_5_0 $site_4_0.lab89
    button $site_5_0.but75 \
        -activebackground #f9f9f9 -activeforeground black \
        -command pSELECT_CLEAR -disabledforeground #a2a2a2 -foreground black \
        -highlightcolor black -text CLEAR 
    vTcl:DefineAlias "$site_5_0.but75" "Button5" vTcl:WidgetProc "Toplevel1" 1
    labelframe $site_5_0.lab70 \
        -foreground #ff0000 -relief flat -text {Select Option} -height 75 \
        -highlightcolor black -width 125 
    vTcl:DefineAlias "$site_5_0.lab70" "Labelframe5" vTcl:WidgetProc "Toplevel1" 1
    set site_6_0 $site_5_0.lab70
    radiobutton $site_6_0.rad71 \
        -activebackground #f9f9f9 -activeforeground black \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text Clear -value 1 -variable FORM(OPT) 
    vTcl:DefineAlias "$site_6_0.rad71" "Radiobutton1" vTcl:WidgetProc "Toplevel1" 1
    radiobutton $site_6_0.rad72 \
        -activebackground #f9f9f9 -activeforeground black \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text None -value 0 -variable FORM(OPT) 
    vTcl:DefineAlias "$site_6_0.rad72" "Radiobutton2" vTcl:WidgetProc "Toplevel1" 1
    pack $site_6_0.rad71 \
        -in $site_6_0 -anchor center -expand 0 -fill none -side left 
    pack $site_6_0.rad72 \
        -in $site_6_0 -anchor center -expand 0 -fill none -side left 
    button $site_5_0.but68 \
        -activebackground #f9f9f9 -activeforeground black -background #ffffff \
        -command {pTable_SELECT $FORM(LYR_SEL) "tm bm" $FORM(OPT)} \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text MARKING 
    vTcl:DefineAlias "$site_5_0.but68" "Button6" vTcl:WidgetProc "Toplevel1" 1
    button $site_5_0.but67 \
        -activebackground #f9f9f9 -activeforeground black -background #009900 \
        -command {pTable_SELECT $FORM(LYR_SEL) "smc sms" $FORM(OPT)} \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text SM 
    vTcl:DefineAlias "$site_5_0.but67" "Button3" vTcl:WidgetProc "Toplevel1" 1
    button $site_5_0.but74 \
        -activebackground #f9f9f9 -activeforeground black \
        -background #d9d9374a139b \
        -command {pTable_SELECT $FORM(LYR_SEL) "1 $INFO(LCNT)" $FORM(OPT)} \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text OUTER 
    vTcl:DefineAlias "$site_5_0.but74" "Button4" vTcl:WidgetProc "Toplevel1" 1
    button $site_5_0.but69 \
        -activebackground #f9f9f9 -activeforeground black \
        -background #ffff624d1eb8 \
        -command {for { set i 2 } { $i < $INFO(LCNT) } { incr i } { lappend inner $i }
pTable_SELECT $FORM(LYR_SEL) $inner $FORM(OPT)} \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text INNER 
    vTcl:DefineAlias "$site_5_0.but69" "Button7" vTcl:WidgetProc "Toplevel1" 1
    button $site_5_0.but76 \
        -activebackground #f9f9f9 -activeforeground black -background #666666 \
        -command {pTable_SELECT $FORM(LYR_SEL) "drill* ld*" $FORM(OPT)} \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text DRILL 
    vTcl:DefineAlias "$site_5_0.but76" "Button8" vTcl:WidgetProc "Toplevel1" 1
    Separator $site_5_0.sep77
    vTcl:DefineAlias "$site_5_0.sep77" "Separator5" vTcl:WidgetProc "Toplevel1" 1
    bind $site_5_0.sep77 <Destroy> {
        Widget::destroy %W; rename %W {}
    }
    button $site_5_0.cpd78 \
        -activebackground #f9f9f9 -activeforeground black -background #ffffff \
        -command {pTable_SELECT $FORM(LYR_SEL) "tm bm" $FORM(OPT)} \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text METAL 
    vTcl:DefineAlias "$site_5_0.cpd78" "Button14" vTcl:WidgetProc "Toplevel1" 1
    button $site_5_0.cpd79 \
        -activebackground #f9f9f9 -activeforeground black -background #ffffff \
        -command {pTable_SELECT $FORM(LYR_SEL) "tm bm" $FORM(OPT)} \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text BBT 
    vTcl:DefineAlias "$site_5_0.cpd79" "Button15" vTcl:WidgetProc "Toplevel1" 1
    Separator $site_5_0.cpd82
    vTcl:DefineAlias "$site_5_0.cpd82" "Separator6" vTcl:WidgetProc "Toplevel1" 1
    bind $site_5_0.cpd82 <Destroy> {
        Widget::destroy %W; rename %W {}
    }
    button $site_5_0.cpd80 \
        -activebackground #f9f9f9 -activeforeground black \
        -background #ffffbbb683d7 \
        -command {pTable_SELECT $FORM(LYR_SEL) "tm bm" $FORM(OPT)} \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text BOARD 
    vTcl:DefineAlias "$site_5_0.cpd80" "Button16" vTcl:WidgetProc "Toplevel1" 1
    button $site_5_0.cpd81 \
        -activebackground #f9f9f9 -activeforeground black -background #009999 \
        -command {pTable_SELECT $FORM(LYR_SEL) "tm bm" $FORM(OPT)} \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text MISC 
    vTcl:DefineAlias "$site_5_0.cpd81" "Button17" vTcl:WidgetProc "Toplevel1" 1
    pack $site_5_0.but75 \
        -in $site_5_0 -anchor center -expand 0 -fill x -side top 
    pack $site_5_0.lab70 \
        -in $site_5_0 -anchor center -expand 0 -fill x -side top 
    pack $site_5_0.but68 \
        -in $site_5_0 -anchor center -expand 0 -fill x -side top 
    pack $site_5_0.but67 \
        -in $site_5_0 -anchor center -expand 0 -fill x -side top 
    pack $site_5_0.but74 \
        -in $site_5_0 -anchor center -expand 0 -fill x -side top 
    pack $site_5_0.but69 \
        -in $site_5_0 -anchor center -expand 0 -fill x -side top 
    pack $site_5_0.but76 \
        -in $site_5_0 -anchor center -expand 0 -fill x -side top 
    pack $site_5_0.sep77 \
        -in $site_5_0 -anchor center -expand 0 -fill x -pady 10 -side top 
    pack $site_5_0.cpd78 \
        -in $site_5_0 -anchor center -expand 0 -fill x -side top 
    pack $site_5_0.cpd79 \
        -in $site_5_0 -anchor center -expand 0 -fill x -side top 
    pack $site_5_0.cpd82 \
        -in $site_5_0 -anchor center -expand 0 -fill x -pady 10 -side top 
    pack $site_5_0.cpd80 \
        -in $site_5_0 -anchor center -expand 0 -fill x -side top 
    pack $site_5_0.cpd81 \
        -in $site_5_0 -anchor center -expand 0 -fill x -side top 
    pack $site_4_0.fra76 \
        -in $site_4_0 -anchor center -expand 0 -fill x -side bottom 
    pack $site_4_0.lab78 \
        -in $site_4_0 -anchor center -expand 0 -fill both -side top 
    pack $site_4_0.lab90 \
        -in $site_4_0 -anchor center -expand 0 -fill both -side top 
    pack $site_4_0.lab69 \
        -in $site_4_0 -anchor center -expand 0 -fill both -side top 
    pack $site_4_0.lab88 \
        -in $site_4_0 -anchor center -expand 1 -fill both -side left 
    pack $site_4_0.lab89 \
        -in $site_4_0 -anchor center -expand 0 -fill both -side right 
    pack $site_3_0.cpd86 \
        -in $site_3_0 -anchor center -expand 1 -fill both -side top 
    frame $top.fra68 \
        -borderwidth 2 -height 75 -highlightcolor black -width 125 
    vTcl:DefineAlias "$top.fra68" "Frame1" vTcl:WidgetProc "Toplevel1" 1
    set site_3_0 $top.fra68
    button $site_3_0.but71 \
        -activebackground #f9f9f9 -activeforeground black -command exit \
        -disabledforeground #a2a2a2 -foreground black -highlightcolor black \
        -text EXIT 
    vTcl:DefineAlias "$site_3_0.but71" "Button2" vTcl:WidgetProc "Toplevel1" 1
    pack $site_3_0.but71 \
        -in $site_3_0 -anchor center -expand 0 -fill x -side top 
    ###################
    # SETTING GEOMETRY
    ###################
    pack $top.lab69 \
        -in $top -anchor center -expand 0 -fill x -side top 
    pack $top.lab67 \
        -in $top -anchor center -expand 1 -fill both -side top 
    pack $top.fra68 \
        -in $top -anchor center -expand 0 -fill x -side top 

    vTcl:FireEvent $base <<Ready>>
}

#############################################################################
## Binding tag:  _TopLevel

bind "_TopLevel" <<Create>> {
    if {![info exists _topcount]} {set _topcount 0}; incr _topcount
}
bind "_TopLevel" <<DeleteWindow>> {
    if {[set ::%W::_modal]} {
                vTcl:Toplevel:WidgetProc %W endmodal
            } else {
                destroy %W; if {$_topcount == 0} {exit}
            }
}
bind "_TopLevel" <Destroy> {
    if {[winfo toplevel %W] == "%W"} {incr _topcount -1}
}

Window show .
Window show .top66

main $argc $argv
