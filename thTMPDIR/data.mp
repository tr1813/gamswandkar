Scale:=2.00;
MagDecl:=4.22;
GridConv:=0.97;
color HelpSymbolColor;
HelpSymbolColor := (0.8, 0.8, 0.8);
background:=(1.00000,1.00000,1.00000);
verbatimtex \input th_enc.tex etex;
%% therion source code
%%
%% therion.mp
%%
%% This file defines low-level MetaPost macros and variables required
%% for generation of map symbols
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: therion.mp,v $
%% $Revision: 1.3 $
%%
%% Copyright (C) 2000-2003 Martin Budaj
%%
%% Some macros are adapted from MPATTERN package of P. Bolek
%%
%% Some macros are used from MetaFun package of H. Hagen
%%
%% --------------------------------------------------------------------
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

%    This file defines low level macros used for map signatures in Therion.
%    Before loading this file set `Scale' variable to numeric value
%    representing denominator of the scale ratio. Internal variable
%    `prologues' is set to 1 by this file. This module loads also
%    symbol libraries.


tracingstats:=1;
prologues:=0;

% Set the random seed to a fixed value so therion reproducibly produces the
% same output for a given input.
randomseed:=42;

if known Background: background:=Background fi;
%TrueScale:=Scale;

% @VARIABLE
% symbol_scale --
%
% <I>internal numeric</I>; in map symbol definitions used for scaling
% in <A HREF="#T">T</A> transformation; recommended
% values are 1 or 2.

%newinternal symbol_scale;
%symbol_scale := 1;

% @VARIABLE
% fill_only --
%
% <I>boolean</I>, used in <A HREF="#thdraw">thdraw</A> and
% <A HREF="#thpattfill">thpattfill</A> commands. When set to false, it has
% no effect, when it is true, it suppresses all drawing
% commands with exception of <I>thpermanentfill</I>, so that only filled
% areas are drawn

boolean fill_only, horiz_labels, transparency;
fill_only := false;
horiz_labels:=true;
transparency:=false;

string ATTR__id, ATTR__survey, ATTR__scrap, NorthDir;
boolean ATTR__scrap_centerline;
picture ATTR__text;
numeric ATTR__height;
boolean ATTR__elevation;
ATTR__scrap_centerline := false;
ATTR__height:=0;
ATTR__elevation:=false;

boolean ATTR__shotflag_splay;
ATTR__shotflag_splay:=false;
boolean ATTR__shotflag_duplicate;
ATTR__shotflag_duplicate:=false;
boolean ATTR__shotflag_approx;
ATTR__shotflag_approx:=false;
boolean ATTR__stationflag_splay;
ATTR__stationflag_splay:=false;


color label_fill_color, label_fill_color_tmp;
label_fill_color := (1.0, 1.0, 1.0);
def push_label_fill_color(expr r,g,b) =
  label_fill_color_tmp := label_fill_color;
  label_fill_color := (r,g,b);
enddef;
def pop_label_fill_color =
  label_fill_color := label_fill_color_tmp;
enddef;
def process_filledlabel(expr cent, rot) =
  begingroup;
    interim bboxmargin:=2.0bp;
    q:=((bbox lab) smoothed 2) rotatedaround (cent, rot);
    fill q withcolor label_fill_color;
    draw lab rotatedaround (cent, rot);
    write_circ_bbox(q);  % without corners smoothing it was enough to use
                         % write_bbox(q);
  endgroup;
enddef;




numeric area_border_errors;
area_border_errors = 0;

% @VARIABLE
% last_write --
%
% <I>numeric</I>; charcode of last figure which contained
% <A HREF="#write_bbox">write_bbox</A> macro; this value is used by
% <A HREF="#close_file">close_file</A> macro. Initially set to -1.

numeric last_write;
last_write = -1;

% @VARIABLE
% strut_string --
%
% <I>string</I> containing combination of the "highest" and "lowest" character
% in used font; it's used by <A HREF="">free_text</A> macro.

%string strut_string;
%strut_string = "(È";

% @VARIABLE
% file_name --
%
% <I>string</I>, name of file, where <I>write_bbox</I> macro writes
% text clipping path

% @VARIABLE
% s ch --
%
% <I>string</I>, temporary string/char variables

string s, ch, file_name, bg_name, clip_name, lang, diff_pos, diff_neg,
     current_scrap, current_src;

% @VARIABLE
% u v w --
%
% <I>internal numeric variables</I> used as basic length units for drawing;
% they are set by <A HREF="#initialize">initialize</A> macro.
% <UL> <LI><I>u</I> -- normal unit decreasing with increasing scale
%      <LI><I>v</I> -- like <I>u</I>, but can increase drammaticaly
%            when some limit is encountered (to get effects like logarithmic
%            scale)
%      <LI><I>w</I> -- nearly constant at all scales
% </UL>

% @VARIABLE
% legend_scale --
%
% <I>numeric</I>, length of the longer side of signatures' legend box

newinternal legend_scale, u,v,w;

% @VARIABLE
% lab Lab --
%
% <I>picture</I>, in which are saved typeset labels

picture lab, Lab;

% @VARIABLE
% T --
%
% <I>transformation</I>, defines transformation function for transforming
% every argument of <A HREF="#thdraw>thdraw</A> and <A HREF="#thfill>thfill</A>
% macros

transform T;

% @VARIABLE
% p,q --
%
% <I>path</I>, for saving temporary paths

path p,q;

% @MACRO
% initialize --
%
% initializes basic length units <A HREF="#u">(u,v,w)</A> and pens used
% in map symbols according to scale. Five circular pens are defined:
% <UL><LI>PenA -- thick; for outlines
%    <LI>PenB, PenC -- thinner; for pits, symbols etc.
%    <LI>PenD -- thinnest; for fine details
%    <LI>PenX -- extra thick; not recommended for use
% </UL>

def fonts_setup (expr t,s,m,l,h) =
  write "\def\updown#1#2{\vbox{" &
        "\offinterlineskip" &
        "\setbox100=\hbox{#1}" &
        "\setbox101=\hbox{#2}" &
        "\ifnum\wd100>\wd101\hsize=\wd100\else\hsize=\wd101\fi" &
        "\centerline{\box100}\vskip4pt" &
        "\centerline{\box101}}}" &
        "\def\thlabel{\thnormalsize}" &
        "\def\thremark{\thsmallsize\si}" &
        "\def\thcomment{\thsmallsize}" &
        "\def\thentrance{\thsmallsize}" &
        "\def\thaltitude{\thsmallsize}" &
        "\def\thstationname{\thsmallsize}" &
        "\def\thdate{\thsmallsize}" &
        "\def\thheight{\thsmallsize}" &
        "\def\thheightpos{+\ignorespaces}" &
        "\def\thheightneg{-\ignorespaces}" &
        "\def\thframed{\thsmallsize}" &
        "\def\thwallaltitude{\thtinysize}"
  to "mptexpre.tex";
  write "\def\thtinysize{\size[" & decimal max(optical_zoom*t,0) & "]}" &
        "\def\thsmallsize{\size[" & decimal max(optical_zoom*s,0) & "]}" &
        "\def\thnormalsize{\size[" & decimal max(optical_zoom*m,0) & "]}" &
        "\def\thlargesize{\size[" & decimal max(optical_zoom*l,0) & "]}" &
        "\def\thhugesize{\size[" & decimal max(optical_zoom*h,0) & "]}"
  to "mptexpre.tex";
  write EOF to "mptexpre.tex";
enddef;

def initialize (expr sc) =

  if unknown BaseScale: BaseScale = sc; fi;
  optical_zoom := BaseScale/sc;

    if BaseScale <= 1:                   % 1:100
        u:=14bp; v:=14bp; w:=12bp;
        fonts_setup(8,10,12,16,24);
    elseif BaseScale <= 2:               % 1:200
        u:=12bp; v:=12bp; w:=12bp;
        fonts_setup(7,8,10,14,20);
    elseif BaseScale <= 5:               % 1:500
        u:=10bp; v:=10bp; w:=12bp;
        fonts_setup(6,7,8,10,14);
    else:
        u:=7bp; v:=14bp; w:=10bp;
        fonts_setup(5,6,7,8,10);
    fi;

    u := optical_zoom * u;
    v := optical_zoom * v;
    w := optical_zoom * w;

    defaultscale := 0.8 * optical_zoom;

    def PenA = pencircle scaled (u/10) enddef;
    def PenB = pencircle scaled (0.7*u/10) enddef;
    def PenC = pencircle scaled (0.5*u/10) enddef;
    def PenD = pencircle scaled (0.35*u/10) enddef;
    def PenX = pencircle scaled (1.2*u/10) enddef;

    legend_scale := 3.14*u;
enddef;

% macro is expanded, we have to know all dimensions and pens before reading
% mpattern macros

initialize(Scale);

vardef thTEX primary s =
  write "verbatimtex \input th_enc.tex etex" to "mptextmp.mp";
  write "btex \mainfont "&s&" etex" to "mptextmp.mp";
  write EOF to "mptextmp.mp";
  scantokens "input mptextmp"
enddef;

% @MACRO
% inscale --
%
% zooms objects to scale specified in legend_scale variable (used in legend
% typesetting)

def inscale =
    xscaled legend_scale yscaled (0.618*legend_scale)
enddef;

% @MACRO
% draw_legend_box --
%
% draws a legend bounding box and resets drawoptions() options

def draw_legend_box =
    clip currentpicture to unitsquare inscale;
    drawoptions();
    pickup PenB;
    draw unitsquare inscale;
enddef;

def clean_legend_box =
  unfill unitsquare inscale;
enddef;

def legend_point (expr name) =
%  if substring (2,9) of name = "station":
%    scantokens(name)((0.5,0.5) inscale);
%  else:
    scantokens(name)((0.5,0.5) inscale,0,1,(0,0));
%  fi;
  draw_legend_box;
enddef;

def legend_line (expr name) =
  scantokens(name)((((-0.3,.5)..(.3,.7)..(.5,.3)..{dir 80}(1.3,.9)) inscale)
                randomized 3mm);
  draw_legend_box;
enddef;

% legend_label
% legend_area
% legend_random

% @MACRO
% roundone --
%
% rounds <I>numeric value</I> to one decimal point

vardef roundone(expr n) =
%    round(10*n)/10
  n
enddef;

% @MACRO
% process_label --
%
% draws a label saved in <I>lab</I> picture variable and calls
% <A HREF="#write_bbox">write_bbox</A> macro.


def process_label (expr cent, rot) =
  begingroup;
    interim bboxmargin:=0.8bp;
    q:=((bbox lab) smoothed 2) rotatedaround (cent, rot);
    draw lab rotatedaround (cent, rot);
    write_circ_bbox(q);  % without corners smoothing it was enough to use
                         % write_bbox(q);
  endgroup;
enddef;

% @MACRO
% process_uplabel --
%
% draws a label into semicircular box and writes clipping path to a file

def process_uplabel =
  begingroup;
    interim bboxmargin := 0.8 bp;
    q:=bbox lab;
  endgroup;
    alef:=.8-.02*(xpart lrcorner q - xpart llcorner q);
%    show alef;
    q:=alef[llcorner q,ulcorner q]{up} .. {down}alef[lrcorner q, urcorner q] --
        lrcorner q -- llcorner q -- cycle;
    draw lab;
    draw q;
    q:=reverse q;
    write_circ_bbox(q);
enddef;

% @MACRO
% process_downlabel --
%
% draws a label into down oriented semicircular box and writes
% clipping path to a file

def process_downlabel =
  begingroup;
    interim bboxmargin := 0.8 bp;
    q:=bbox lab;
  endgroup;
    alef:=1-(.8-.02*(xpart lrcorner q - xpart llcorner q));
    q:=alef[llcorner q,ulcorner q]{down} ..
        {up}alef[lrcorner q, urcorner q] --
        urcorner q -- ulcorner q -- cycle;
    draw lab;
    draw q;
    write_circ_bbox(q);
enddef;

% @MACRO
% process_updownlabel --
%
% draws a label split into down and up oriented semicircular boxes and
% writes clipping path to a file

def process_updownlabel =
  begingroup;
    interim bboxmargin := 0.8 bp;
    p:=bbox lab;
  endgroup;
    leftside:=xpart llcorner p;
    rightside:=xpart lrcorner p;
    draw (xpart llcorner p,.5[ypart llcorner p,ypart ulcorner p]) --
         (xpart lrcorner p,.5[ypart llcorner p,ypart ulcorner p]);
    alef:=1.05-.02*(xpart lrcorner p - xpart llcorner p);
%    alef:=.8-.02*(rightside-leftside);
    p:=alef[(leftside, ypart llcorner p),(leftside, ypart ulcorner p)]{up} ..
       {down}alef[(rightside, ypart lrcorner p), (rightside, ypart urcorner p)]
        -- alef[(rightside, ypart urcorner p), (rightside, ypart lrcorner p)]{down}
        .. {up}alef[(leftside, ypart ulcorner p),(leftside, ypart llcorner p)]
        -- cycle;
%    p:=alef[llcorner p,ulcorner p]{up} .. {down}alef[lrcorner p, urcorner p] --
%        aleff[llcorner p,ulcorner p]{down} ..
%        {up}aleff[lrcorner p, urcorner p] -- cycle;
    draw lab;
    draw p;
    p:=reverse p;
    write_circ_bbox(p);
enddef;

def process_updownlabel_OLD =
    p:=bbox lab;
    q:=bbox Lab;
    leftside:=min(xpart llcorner p, xpart ulcorner q);
    rightside:=max(xpart lrcorner p, xpart urcorner q);
    draw .5[(leftside, ypart llcorner p),(leftside, ypart ulcorner q)] --
         .5[(rightside,ypart lrcorner p),(rightside,ypart urcorner q)];
    alef:=.8-.02*(rightside-leftside);
    q:=alef[(leftside, ypart llcorner p),(leftside, ypart ulcorner p)]{up} ..
       {down}alef[(rightside, ypart lrcorner p), (rightside, ypart urcorner p)]
        -- alef[(rightside, ypart urcorner q), (rightside, ypart lrcorner q)]{down}
        .. {up}alef[(leftside, ypart ulcorner q),(leftside, ypart llcorner q)]
        -- cycle;
    draw lab;
    draw Lab;
    draw q;
    q:=reverse q;
    write_circ_bbox(q);
enddef;

% @MACRO
% process_boxedlabel --
%
% draws a label into circular box and writes
% clipping path to a file

def process_boxedlabel =
  begingroup;
    interim bboxmargin:=1.0bp;
    q:=bbox lab;
    draw lab;
    draw q;
    write_bbox(q);
  endgroup;
enddef;

% @MACRO
% process_circledlabel --
%
% draws a label into circular box and writes
% clipping path to a file

def process_circledlabel =
  begingroup;
    interim bboxmargin := 0.4 bp;
    q:=bbox lab;
  endgroup;
    q:=point 0 of q .. point 1 of q .. point 2 of q .. point 3 of q .. cycle;
    draw lab;
    draw q;
    write_circ_bbox(q);
enddef;


% @MACRO
% write_bbox --
%
% Arguments:
%   <I>path</I> variable -- rectangular bounding box of a label;
%   assumptions: path is cyclic, counterclockwise oriented, with four points,
%   composed from linear segments;
%   see general <A HREF="#write_circ_bbox">write_circ_bbox</A> macro
% Results:
%   one file per figure which uses labels with a clipping path in pseudo-pdf
%   format

def write_bbox (expr q) =
    file_name := jobname & "." & decimal(charcode) & "bbox";
    for i:=4 downto 0:
        s  :=  decimal(roundone(xpart point i of q)) & " "
             & decimal(roundone(ypart point i of q))
             & if i=4: " m " else: " l" fi;
        write s to file_name;
    endfor;
    last_write := charcode;
enddef;

% @MACRO
% write_circ_bbox --
%
% Arguments:
%   <I>path</I> variable, only assumption is that <I>path</I> is cyclic
%   and counterclockwise oriented.
% Results:
%   one file per figure which uses labels with a clipping path in pseudo-pdf
%   format

def write_circ_bbox expr q =
    file_name := jobname & "." & decimal(charcode) & "bbox";
    tmp:=length q;
    s :=  decimal(roundone(xpart point tmp of q)) & " "
             & decimal(roundone(ypart point tmp of q)) & " m";
    write s to file_name;
    for i:=tmp downto 1:
        s :=  decimal(roundone(xpart precontrol i of q)) & " "
             & decimal(roundone(ypart precontrol i of q)) & " "
             & decimal(roundone(xpart postcontrol i-1 of q)) & " "
             & decimal(roundone(ypart postcontrol i-1 of q)) & " "
             & decimal(roundone(xpart point i-1 of q)) & " "
             & decimal(roundone(ypart point i-1 of q)) & " c";
        write s to file_name;
    endfor;
    last_write := charcode;
enddef;

% @MACRO
% close_file --
%
% closes file with a clipping path; it's invoked by <I>endchar</I> macro

def close_file =
    if last_write=charcode:
        write EOF to jobname & "." & decimal(charcode) & "bbox";
    fi;
enddef;

% endchar should run close_file macro

extra_endfig := "close_file;";

% @MACRO
% thdraw --
%
% like plain MetaPost's <I>draw</I>, but draws a <I>path</I> transformed
% (rotated, scaled, shifted) to scrap's coordinates according T variable.
% (If <I>fill_only=false</I>)

def thdrawoptions(text t) =
  def _thop_ = t enddef
enddef;
thdrawoptions();

def thdraw expr p =
  if not fill_only:
    addto currentpicture
    if picture p:
      also (p transformed T)
    else:
      doublepath (p transformed T) withpen currentpen
    fi
    _thop_  _op_
  else:
    addto currentpicture also nullpicture
  fi
enddef;

% @MACRO
% thfill --
%
% fills a <I>path</I> transformed
% (rotated, scaled, shifted) to scrap's coordinates according T variable.
% Filled areas are clipped (like most
% other lines and points) with a clipping path around text labels.


def thfill expr c =
    addto currentpicture contour (c transformed T) _thop_ _op_
enddef;

def thfilldraw expr c =
  if not fill_only:
    addto currentpicture contour (c transformed T) withpen currentpen _thop_ _op_
  else:
    addto currentpicture contour (c transformed T) _thop_ _op_
  fi
enddef;

def thunfill expr c =
    thfill c withcolor background
enddef;

def thundraw expr p =
    thdraw p withcolor background
enddef;

def thunfilldraw expr c =
    thfilldraw c withcolor background
enddef;

def thclean expr c =
  if transparency:
    thfill c withtransparentcolor tr_bg
  else:
    thunfill c
  fi;
enddef;

def thPatternFill (expr Path, Pattern) =
  T:=identity;
  thclean Path;
  thfill Path withpattern Pattern;
enddef;

%def thLegendPatternFill (expr Path, Pattern) =
%  T:=identity;
%  thfill Path withpattern Pattern;
%enddef;

% for drawarrow:

def _finarr text t =
  thdraw _apth t;
  thfilldraw arrowhead _apth  t
enddef;

% @MACRO
% thpermanentfill --
%
% Fills specified area with a solid color; this area is not affected by
% text clipping path

%def thpermanentfill expr c =
%    addto currentpicture contour (c transformed T) _thop_ _op_
%enddef;

let thpermanentfill = thfill;


primarydef p aligned al=
  p shifted (xpart al * xpart U, ypart al * ypart U)
enddef;

% macros for drawing scraps in upper and lower levels; filled lower scraps
% require special treatment (MetaPost doesn't support non-continuous paths).
% We can't use one file for both, while PDF XObject has to be explicitly
% filled or stroked. Second macro writes also pseudo-pdf code of a clipping
% path for given scrap

boolean drawnext;
drawnext:=true;

def draw_upscrap (expr isout)(text t) =
  path q;
  for i=t:
    if (numeric i):
      if (i=1): drawnext:=true; else: drawnext:=false; fi;
    else:
      if drawnext: draw i withpen PenD; fi;
      if not known q: q:=i; else: q:=q -- i; fi;
    fi;
  endfor;
  if not cycle q: q:=q -- cycle; fi;
  if turningnumber q = 0:
      thwarning("scrap outline intersects itself");
  fi;
  if isout=1:
    if turningnumber q > 0: q := reverse q; fi;
  else:
    if turningnumber q < 0: q := reverse q; fi;
  fi;
  addto bgfill contour q;
enddef;

% following macro writes noncontinuous PostScript path directly to EPS file
% (filled background and clipping path)

picture bgfill;
bgfill:=nullpicture;

def draw_downscrap =
  bg_name := jobname & "." & decimal(charcode) & "bg";
  clip_name := jobname & "." & decimal(charcode) & "clip";
  write "%!PS" to bg_name;
  write "%%BoundingBox: " &
     decimal floor xpart llcorner bgfill & " " &
     decimal floor ypart llcorner bgfill & " " &
     decimal ceiling xpart urcorner bgfill & " " &
     decimal ceiling ypart urcorner bgfill
     to bg_name;
  write "%%Page: 1 1" to bg_name;
  write "newpath" to bg_name;
  for qq within bgfill:
    q := pathpart qq;
    tmp:=length q;
    s := decimal(roundone(xpart point tmp of q)) & " "
             & decimal(roundone(ypart point tmp of q)) & " m";
    write s & "oveto" to bg_name;
    write s to clip_name;
    for i:=tmp downto 1:
        s :=  decimal(roundone(xpart precontrol i of q)) & " "
             & decimal(roundone(ypart precontrol i of q)) & " "
             & decimal(roundone(xpart postcontrol i-1 of q)) & " "
             & decimal(roundone(ypart postcontrol i-1 of q)) & " "
             & decimal(roundone(xpart point i-1 of q)) & " "
             & decimal(roundone(ypart point i-1 of q)) & " c";
        write s & "urveto" to bg_name;
        write s to clip_name;
    endfor;
  endfor;
  write "closepath fill" to bg_name;
  write "showpage" to bg_name;
  write "%%EOF" to bg_name;
  write EOF to bg_name;
  write EOF to clip_name;
  bgfill:=nullpicture;
enddef;



vardef buildcycle(text ll) =
  save ta_, tb_, k_, i_, pp_; path pp_[];
  k_=0;
  for q=ll: pp_[incr k_]=q; endfor
  i_=k_;
  for i=1 upto k_:
    (ta_[i], length pp_[i_]-tb_[i_]) =
      pp_[i] intersectiontimes reverse pp_[i_];
    if ta_[i]<0:
      message("[Error: area borders "& area_border[i] &" and "&
         area_border[i_] &" don't intersect in scrap " & current_scrap &
         " (file " & current_src & ")]");
      area_border_errors := area_border_errors + 1;
    fi
    i_ := i;
  endfor
  for i=1 upto k_: subpath (ta_[i],tb_[i]) of pp_[i] .. endfor
    cycle
enddef;

vardef unitvector primary z =
  if (z<>(0,0)):
    z/abs z
  else:
    hide(thwarning("strange path"))
    (0,epsilon)
  fi
enddef;

def thwarning (expr m) =
  message("[Warning: " & m & " in scrap " & current_scrap & "]");
enddef;

def check_area_borders =
  if area_border_errors > 0:
  fi;
enddef;

%%%%%%%%%%%% Map symbols management %%%%%%%%%%%%%%%%%%%

def mapsymbol (expr name, set, warning) =
  string s, stype, lname, ID;
  stype = substring (0,1) of name;
  lname = name & "_" & set;
  ID := "ID_" & lname;
  if (known scantokens ID):
    if stype = "a":
      s = "def " & name & " = scantokens(" & ditto & lname & ditto & ") enddef;";
    else:
      s = "let " & name & " = " & lname & ";";
    fi;
    scantokens s;
  elseif warning:
    message("[Warning: undefined symbol `" & lname & "']");
  fi;
enddef;

%def hidesymbol (expr name) =
%  string s, stype;
%  stype = substring (0,1) of name;
%  if stype = "a":
%    s = "def " & name & " = scantokens(" & ditto & "a_empty" & ditto & ") enddef;";
%  else:
%    s = "vardef " & name & "@# (text t) = enddef;";
%  fi;
%  scantokens s;
%  write name to "missed.dat";
%enddef;

def initsymbol (expr name) =
  s := "ID_" & name & " = 1";
  scantokens s;
enddef;

%%%

% comment out groups in order to use 'save ATTR_*' appropriately

def beginfig(expr c) =
%  begingroup
  charcode:=c;
  clearxy; clearit; clearpen;
  pickup defaultpen;
  drawoptions();
  scantokens extra_beginfig;

  save smartll, smartur;
  pair smartll[], smartur[];
  smart_count := 0;
enddef;

def endfig =
  scantokens extra_endfig;
  shipit;
%  endgroup
enddef;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% P. Bolek's MPATTERN package adapted and simplified for Therion
% (with the same user interface except of patterncolor)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

string Pname_, PXYsteps_;
string Pmatrix_;

numeric Pnum_; Pnum_=0;

def PmakeBB_=
   PBBox_ := "[" & decimal Plft_ & " " & decimal Plow_ & " "
   & decimal Prt_ & " " & decimal Pup_ & "]";
enddef;

def Psteps_=
   PXYsteps_ := decimal
     if unknown PXStep_: (Prt_-Plft_) else: PXStep_ fi
   & ":" & decimal
     if unknown PYStep_: (Pup_-Plow_) else: PYStep_ fi;
enddef;

vardef Pfindbounds_=
   Plow_ = ypart (llcorner currentpicture);
   Plft_ = xpart (llcorner currentpicture);
   Pup_ = ypart (urcorner currentpicture);
   Prt_ = xpart (urcorner currentpicture);
   PmakeBB_;
enddef;

def PmakePattern_(expr name)=
  write decimal (Pnum_*epsilon) & ":"
    & jobname & "." & decimal charcode & ":"
    & PBBox_ & ":"
    & PXYsteps_ & ":"
    & Pmatrix_
  to "patterns.dat"
enddef;

% User interface macros

vardef patternbbox(expr a)(text b)=
   save Pi_, Pz_;
   numeric Pi_, Pz_[];
   if pair a:
      Plft_:=min(xpart(a),xpart(b)); Plow_:=min(ypart(a),ypart(b));
      Prt_:=max(xpart(a),xpart(b));  Pup_:=max(ypart(a),ypart(b));
   else:
      Pi_=1;
      for t=b:
	 Pz_[Pi_]=t;
	 Pi_:=Pi_+1;
      endfor;
      Plft_:=min(a,Pz_2);   Plow_:=min(Pz_1,Pz_3);
      Prt_:=max(a,Pz_2); Pup_:=max(Pz_1,Pz_3);
   fi;
   PmakeBB_;
enddef;

def beginpattern(suffix name)=
  numeric PXStep_, PYStep_;
  numeric Plow_, Plft_, Pup_, Prt_;
  string PBBox_;
  Pmatrix_:="[1 0 0 1 0 0]";
  Pname_:=str name;
  Pnum_:=Pnum_+1;
  beginfig(Pnum_+4000);
enddef;

def endpattern=
  if unknown PBBox_:
     Pfindbounds_;
  fi;
  endfig;
  Psteps_;
  PmakePattern_(Pname_);
  scantokens(Pname_ & "=Pnum_;");
enddef;

picture pattpict;
color patterncolor_;
patterncolor_ := black;

primarydef p withpattern s=
  if known s:

    hide(pattpict := image(draw (0,0)--(10,10));
      for i within pattpict:
        patterncolor_ := (redpart i, greenpart i, bluepart i);
      endfor;)

    p withcolor (epsilon, 10*epsilon, s*epsilon)
    if known mpversion:
      if scantokens(mpversion)>=1.000:
        withprescript(decimal redpart   patterncolor_ & " " &
                      decimal greenpart patterncolor_ & " " &
                      decimal bluepart  patterncolor_ & " THsetpatterncolor")
      fi;
    fi;
  else:
    p withcolor (1,0,0);
    message("Warning: undefined pattern ignored");
  fi;
enddef;

def patterntransform expr t=
   Pmatrix_ := "[" & decimal xxpart t
              & " " & decimal yxpart t
              & " " & decimal xypart t
              & " " & decimal yypart t
              & " " & decimal xpart t
              & " " & decimal ypart t & "]";
enddef;

def patternxstep expr t=
   PXStep_ = t;
enddef;

def patternystep expr t=
   PYStep_ = t;
enddef;

def patternstep text t=
   if pair t:
      PXStep_ = xpart t;
      PYStep_ = ypart t;
   else:
      (PXStep_,PYStep_)=t;
   fi;
enddef;

def patterncolor expr t=
  message("Warning: patterncolor not supported in Therion");
enddef;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% end of pattern macros
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% transparent rgb colors

numeric RGBnum; RGBnum=0;
string RGBname;

def def_transparent_rgb (suffix name)(expr r, g, b) =
  RGBnum := RGBnum+1;
  RGBname := str name;
  write decimal (RGBnum*epsilon) & ":"
    & decimal r & " "
    & decimal g & " "
    & decimal b
  to "rgbcolors.dat";
  scantokens(RGBname & ":=RGBnum;");
enddef;

primarydef p withtransparentcolor s=
   p withcolor (epsilon, 12*epsilon, s*epsilon);
enddef;

def_transparent_rgb(tr_white, 1, 1, 1);
def_transparent_rgb(tr_blue, 0, 0, 1);
def_transparent_rgb(tr_black, 0, 0, 0);
def_transparent_rgb(tr_bg,
               redpart background, greenpart background, bluepart background);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% some useful macros from H. Hagen's MetaFun package
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

vardef paired (expr d) =
  if pair d : d else : (d,d) fi
enddef ;

primarydef p randomshifted s =
  begingroup ; save ss ; pair ss ; ss := paired(s) ;
  p shifted (-.5xpart ss + uniformdeviate xpart ss,
             -.5ypart ss + uniformdeviate ypart ss)
  endgroup
enddef ;

primarydef p randomized s =
  (if path p :
    for i=0 upto length(p)-1 :
      ((point       i    of p) randomshifted s) .. controls
      ((postcontrol i    of p) randomshifted s) and
      ((precontrol (i+1) of p) randomshifted s) ..
    endfor
    if cycle p :
      cycle
    else :
      ((point length(p) of p) randomshifted s)
    fi
  elseif pair p :
    p randomshifted s
  elseif color p :
    if color s :
      (uniformdeviate redpart   s * redpart   p,
       uniformdeviate greenpart s * greenpart p,
       uniformdeviate bluepart  s * bluepart  p)
    elseif pair s :
      ((xpart s + uniformdeviate (ypart s - xpart s)) * p)
    else :
      (uniformdeviate s * p)
    fi
  else :
    p + uniformdeviate s
  fi)
enddef ;

primarydef p llmoved d =
  ((llcorner p) shifted (-xpart paired(d),-ypart paired(d)))
enddef ;

primarydef p lrmoved d =
  ((lrcorner p) shifted (+xpart paired(d),-ypart paired(d)))
enddef ;

primarydef p urmoved d =
  ((urcorner p) shifted (+xpart paired(d),+ypart paired(d)))
enddef ;

primarydef p ulmoved d =
  ((ulcorner p) shifted (-xpart paired(d),+ypart paired(d)))
enddef ;

primarydef p smoothed d =
  (p llmoved (-xpart paired(d),0) -- p lrmoved (-xpart paired(d),0) {right} ..
   p lrmoved (0,-ypart paired(d)) -- p urmoved (0,-ypart paired(d)) {up}    ..
   p urmoved (-xpart paired(d),0) -- p ulmoved (-xpart paired(d),0) {left}  ..
   p ulmoved (0,-ypart paired(d)) -- p llmoved (0,-ypart paired(d)) {down}  .. cycle)
enddef ;

vardef punked primary p =
  (point 0 of p for i=1 upto length(p)-1 : -- point i of p endfor
   if cycle p : -- cycle else : -- point length(p) of p fi)
enddef ;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% end of MetaFun macros
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% we input map symbol definitions




%%%%% INPUT thPoint %%%%%


%% therion source code
%%
%% This file defines macros for point map symbols
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: thPoint.mp,v $
%% $Revision: 1.8 $
%%
%% Copyright (C) 2000-2004 Martin Budaj
%%
%% --------------------------------------------------------------------
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

pair U;

def p_stalactite_UIS(expr pos,theta,sc,al) =
    U:=(.15u, .4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
    thdraw (0,.15u) -- (.15u,.4u);
enddef;

def p_stalagmite_UIS(expr pos,theta,sc,al) =
    U:=(.15u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
    thdraw (0,-.15u) -- (.15u,-.4u);
enddef;

def p_pillar_UIS(expr pos,theta,sc,al) =
    U:=(.15u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,.15u)--(0,-.15u);
    thdraw (-.15u,-.4u)--(0,-.15u)--(.15u,-.4u);
    thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
enddef;

def p_curtain_UIS(expr pos,theta,sc,al) =
    U:=(.15u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
    thdraw (0,.15u)--(0,0){dir 180}..(-.12u,-.11u)..{dir 0}(0,-.22u)--(0,-.4u);
enddef;

def p_helictite_UIS(expr pos,theta,sc,al) =
    U:=(.2u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,.4u)--(0,-.4u);
    p := (-.2u,.4u)---(-.2u,.1u){down}..{dir -10}(-.1u,0.02u)---origin;
    thdraw p;
    thdraw p reflectedabout (origin,(0,u)) reflectedabout (origin,(u,0));
enddef;

def p_sodastraw_UIS(expr pos,theta,sc,al) =
    U:=(.5u,.25u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,.2u)--(.5u,.2u);
    pickup PenD;
    thdraw (-.4u,.2u)--(-.4u,0);
    thdraw (-.12u,.2u)--(-.12u,-.25u);
    thdraw (.02u,.2u)--(.02u,-.1u);
    thdraw (.23u,.2u)--(.23u,-.19u);
    thdraw (.35u,.2u)--(.35u,-.15u);
enddef;

def p_crystal_UIS (expr pos,theta,sc,al)=
    U:=(.35u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := ((-.35*u,0)--(.35*u,0));
    thdraw p;
    thdraw p rotated (60);
    thdraw p rotated (120);
enddef;

def p_flowstone_UIS (expr pos,theta,sc,al)=
    U:=(.45u,.1u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := ((-.15*u,0)--(.15*u,0));
    thdraw p shifted (.3u,-.1u);
    thdraw p shifted (-.3u,-.1u);
    thdraw p shifted (0,.1u);
enddef;

def p_moonmilk_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.2u){up}..{dir -60}(-.18u,-.105u){dir 80}..
        {dir-80}(.18u,-.105u){dir 60}..{down}(.5u,-.2u);
enddef;

def p_wallcalcite_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.2u,-.2u)--(0,.1u)--(.2u,-.2u);
enddef;

def p_popcorn_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.2u)--(.5u,-.2u);
    pickup PenD;
    thdraw (-.3u,-.2u)--(-.3u,.1u);
    thdraw (0,-.2u)--(0,.1u);
    thdraw (.3u,-.2u)--(.3u,.1u);
    thfill fullcircle scaled .2u shifted (-.3u,.1u);
    thfill fullcircle scaled .2u shifted (0,.1u);
    thfill fullcircle scaled .2u shifted (.3u,.1u);
enddef;

def p_disk_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.2u,-.3u)--origin--(.2u,-.3u);
    p:=fullcircle scaled .3u shifted (0,.15u);
    thclean p;
    thdraw p;
enddef;

def p_gypsum_NSS (expr pos,theta,sc,al)=
    U:=(.25u,.25u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.25u,0)--(.25u,0);
    thdraw (0,-.25u)--(0,.25u);
enddef;

def p_aragonite_NSS (expr pos,theta,sc,al)=
    U:=(.3u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-.4u)--(0,.3u);
    thdraw (0,-.1u){dir 40}..{dir 5}(.3u,.08u);
    thdraw (0,-.1u){dir 140}..{dir 175}(-.3u,.08u);
    thdraw (0,.2u){dir 30}..{dir 5}(.25u,.3u);
    thdraw (0,.2u){dir 150}..{dir 175}(-.25u,.3u);
enddef;


def p_cavepearl_SKBB (expr pos,theta,sc,al)=
    U:=(.25u,.25u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=fullcircle scaled .25u shifted (0,.16u);
    thdraw p;
    thdraw p rotated 120;
    thdraw p rotated 240;
enddef;

def p_gypsumflower_NSS (expr pos,theta,sc,al)=
    U:=(.4u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
%    thdraw (.2u,0){left}..(0,.2u)..(.25u,.35u)..(.5u,0)..
%        (.1u,-.3u)..{dir 125}(-.5u,.2u);
    thdraw (.18u,0){left}..(0,.15u)..(.2u,.3u)..(.4u,0)..
        (.15u,-.28u)..{dir 120}(-.4u,.15u);
enddef;

def p_rimstonepool_ASF (expr pos,theta,sc,al)=
    U:=(.4u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := (-.4u,.2u){dir -70}..{dir 70}(.4u,.2u);
    thfill buildcycle(p,((.5u,.1u)--(-.5u,.1u)));
    thdraw p;
enddef;

def p_rimstonedam_ASF (expr pos,theta,sc,al)=
    U:=(.4u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.4u,.2u){dir -70}..{dir 70}(.4u,.2u);
enddef;

def p_anastomosis_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(-.4u,-.2u)--(-.3u,-.3u)--(0,.3u)--(.1u,.2u);
    thdraw p;
    thdraw p shifted (.3u,0);
enddef;

def p_karren_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.3u){dir -85}..{dir 85}(-.32u,-.3u)..(-.28u,.3u){dir 85}..
        {dir -85}(-.12u,.3u)..(-.08u,-.3u){dir-85}..{dir 85}(.08u,-.3u)..
        {dir85}(.12u,.3u)..(.28u,.3u){dir -85}..(.32u,-.3u){dir -85}..
        {dir 85}(.5u,-.3u);
enddef;

def p_scallop_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-.4u){dir 125}..{dir 105}(-.2u,.1u){up}..
        {down}(.2u,.1u){dir -105}...{dir -125}(0,-.4u);
enddef;

def p_flute_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,.2u)--(.5u,.2u);
    thdraw (-.3u,.2u){dir -70}..{dir 70}(.3u,.2u);
enddef;

def p_raft_NSS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,.2u){dir -80}..(-.3u,-.2u)..origin..(.3u,.2u)..
        {dir -80}(.5u,-.2u);
enddef;

def p_raftcone_NSS (expr pos,theta,sc,al)=
    U:=(.3u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,-.4u)--(0,.4u)--(.3u,-.4u);
enddef;

def p_spring_SKBB (expr pos,theta,sc,al)=
  U:=(.3u,.2u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.3u,.2u){down}..(0,-.2u)..{up}(.3u,.2u);
enddef;

def p_sink_SKBB (expr pos,theta,sc,al)=
  U:=(.3u,.2u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.3u,-.2u){up}..(0,.2u)..{down}(.3u,-.2u);
enddef;

def p_narrowend_UIS (expr pos,theta,sc,al)=
    U:=(.1u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.1u,-.4u)--(-.1u,.4u);
    thdraw (.1u,-.4u)--(.1u,.4u);
enddef;

def p_lowend_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.1u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.4u,-.1u)--(.4u,-.1u);
    thdraw (-.4u,.1u)--(.4u,.1u);
enddef;

def p_lowend_NSS (expr pos,theta,sc,al)=
    U:=(.4u,0);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.4u,0)--(.4u,0);
enddef;

def p_flowstonechoke_NSS (expr pos,theta,sc,al)=
    U:=(.4u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(-.4u,-.4u){right}..{dir120}(-.2u,-.2u){dir -20}..{up}(0,0);
    thdraw p;
    thdraw p shifted (0,.2u);
    thdraw p reflectedabout (origin,down);
    thdraw p reflectedabout (origin,down) shifted (0,.2u);
enddef;

def p_breakdownchoke_NSS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.1u)--(-.15u,.05u)--(-.48u,.2u)--cycle;
    thdraw (-.2u,-.2u)--(.15u,-.18u)--(-.08u,.14u)--cycle;
    thdraw (.1u,0)--(.4u,-.1u)--(.5u,.2u)--(.1u,.2u)--cycle;
enddef;

def p_bedrock_ASF (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,0)--(.5u,0);
    thdraw (-.3u,0)--(-.3u,.2u);
    thdraw (.3u,0)--(.3u,-.2u);
enddef;

def p_sand_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenB;
    thdraw (0,.2u);
    thdraw (0,.2u) rotated 120;
    thdraw (0,.2u) rotated 240;
enddef;

def p_clay_SKBB (expr pos,theta,sc,al) =
    U:=(.3u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,0){up}..origin{down}..{up}(0.3u,0);
enddef;

def p_pebbles_UIS (expr pos,theta,sc,al)=
    U:=(.45u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=superellipse((.2u,0),(0,.1u),(-.2u,0),(0,.-.1u),.75);
    thdraw p rotated 20 shifted (0,.25u);
    thdraw p rotated -37 shifted (.25u,-.25u);
    thdraw p rotated -62 shifted (-.25u,-.25u);
enddef;

def p_debris_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,-.4u)--(0,-.22u)--(-.4u,-.1u)--cycle;
    thdraw (.2u,-.4u)--(.4u,-.1u)--(.1u,-.1u)--cycle;
    thdraw (-.1u,0)--(.2u,.3u)--(-.2u,.3u)--cycle;
enddef;

def p_blocks_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.5u)--(.3u,-.4u)--(-.17u,.2u)--cycle;
    thdraw (.25u,-.25u)--(.5u,-.15u)--(.3u,.5u)--(-.1u,.5u)--cycle;
    thdraw (-.27u,0)--(-.1u,.3u)--(-.5u,.35u)--cycle;
    pickup PenD;
    thdraw (-.5u,-.5u)--(-.1u,-.2u)--(-.17u,.2u);
    thdraw (-.1u,-.2u)--(.3u,-.4u);
    thdraw (.25u,-.25u)--(.3u,0)--(.2u,.2u)--(-.1u,.5u);
    thdraw (.3u,.5u)--(.2u,.2u);
    thdraw (.5u,-.15u)--(.3u,0);
enddef;

def p_water_UIS (expr pos,theta,sc,al)=
    U:=(.425u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenD;
    p:=fullcircle xscaled (.85u) yscaled (.6u);
    thfill p withpattern pattern_water_UIS;
    thdraw p;
enddef;

def p_ice_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := (0,.05u)--(0,.35u);
    thdraw p;
    thdraw p shifted (-.25u,-.3u);
    thdraw p shifted (.25u,-.3u);
    p := (-0.15u,.2u)--(0.15u,.2u);
    thdraw p;
    thdraw p shifted (-.25u,-.3u);
    thdraw p shifted (.25u,-.3u);
enddef;

def p_snow_SKBB (expr pos,theta,sc,al)=
    U:=(.35u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := origin--(0,.25*u);
    q := ((0,.35u)--(0,0.25u)--(0.1u,0.25u)) rotatedaround ((0,0.25u),45);
    thdraw p;
    thdraw p rotated (60);
    thdraw p rotated (120);
    thdraw p rotated (180);
    thdraw p rotated (240);
    thdraw p rotated (300);
    thdraw q;
    thdraw q rotated (60);
    thdraw q rotated (120);
    thdraw q rotated (180);
    thdraw q rotated (240);
    thdraw q rotated (300);
enddef;


def p_archeomaterial_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := fullcircle scaled .8u;
    thdraw (-.5u,-.5u)--origin cutbefore p;
    thdraw (-.5u,.5u)--origin cutbefore p;
    thdraw origin--(.4u,0);
    thdraw p;
enddef;

def p_paleomaterial_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    thfill (-.4u,-.2u)..(-.2u,-.08u)---(-.1u,.05u)---(0,.2u)..(-.03u,.4u)..
        (.2u,.3u)..(.35u,.25u)..(.2u,.2u)---origin---(-.1u,-.17u)..
        (-.08u,-.25u){dir -120}..(-.3u,-.23u)
        ..cycle;
enddef;

def p_guano_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.4u,.2u){dir 40}..{down}(0,-.35u){up}..{dir-40}(.4u,.2u);
enddef;

def p_vegetabledebris_ASF (expr pos,theta,sc,al)=
    U:=(.38u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,-.3u)--(0,.3u);
    thdraw (0,-.3u)--(.3u,.3u);
    thdraw (-.25u,.13u)--(.38u,.13u);
    thdraw (-.38u,-.13u)--(.25u,-.13u);
enddef;

def p_root_ASF (expr pos,theta,sc,al)=
    U:=(.1u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.1u,-.5u)--(-.1u,.5u);
    p:=(-.1u,-.3u)--(.1u,-.5u);
    thdraw p;
    thdraw p shifted (0,.2u);
    thdraw p shifted (0,.4u);
enddef;

def p_entrance_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    thfill (-.2u,-.5u)--(0,.5u)--(.2u,-.5u)--cycle;
enddef;

def p_waterflow_paleo_UIS (expr pos,theta,sc,al)=
    U:=(.2u,u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-u)--(0,u);
    thdraw halfcircle scaled .4u shifted (0,-.4u);
    p:=(-.15u,.6u)--(0,u)--(.15u,.6u)--cycle;
    thfill p;
    thdraw p;
enddef;

def p_gradient_UIS (expr pos,theta,sc,al)=
    U:=(.15u,u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-u)--(0,u);
    p:=(-.15u,.6u)--(0,u)--(.15u,.6u)--cycle;
    thfill p;
    thdraw p;
enddef;

def p_gradient_BCRA (expr pos,theta,sc,al)=
    U:=(.25u,0.7u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    thfill (-.25u,-0.7u)--(0,.7u)--(.25u,-.7u)--cycle;
enddef;

% by Philip Schuchardt
def p_gradient_NSS (expr pos,theta,sc,al) =
  U:=(.7u, .6u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;

  thdraw (-.3u, -.5u) -- (-.7u, -.2u);
  thdraw (-.2u, -.4u) -- (-.4u, .3u);
  thdraw (0u, -.3u) -- (0u, .6u);
  thdraw (.3u, -.5u) -- (.7u, -.2u);
  thdraw (.2u, -.4u) -- (.4u, .3u);
enddef;

def p_waterflow_permanent_UIS (expr pos,theta,sc,al)=
    U:=(.15u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(0,.5u){down}..(.12u,.3u)..(-.15u,.15u)..(.13u,0)..
        (-.08u,-.2u)..{down}(0,-.5u);
    p:=p rotated 180;
    thdraw p;
    thdrawoptions();
    oldahlength:=ahlength; ahlength:=2.5pt*optical_zoom;
    thdraw arrowhead p;
    thfill arrowhead p;
    ahlength:=oldahlength;
enddef;

def p_waterflow_intermittent_UIS (expr pos,theta,sc,al)=
  thdrawoptions(dashed evenly scaled (.5 * optical_zoom));
  p_waterflow_permanent_UIS (pos,theta,sc,al);
  thdrawoptions();
enddef;

def p_airdraught_UIS (expr pos,theta,sc,al)=
  U:=(.2u,u);
  T:=identity aligned al rotated theta scaled 1 shifted pos;
  pickup PenC;
  thdraw (0,u)--(0,-0.8u);
	p:=(-.2u,.65u){dir 20}..{dir 90}(0,u);
	thdraw p;
	thdraw p reflectedabout (origin,(0,u));
	for i:=1 upto round(3+2*mlog(sc)/mlog 2):
	  thdraw (0,-(1-0.2i)*u)--(.2u,-(1-0.2(i-1))*u);
	endfor;
enddef;

def p_airdraught_winter_UIS (expr pos,theta,sc,al)=
  U:=(.2u,u);
  T:=identity aligned al rotated theta scaled 1 shifted pos;
  pickup PenC;
  thdraw (0,u)--(0,-0.8u);
  p:=(-.2u,.65u){dir 20}..{dir 90}(0,u);
  thdraw p;
  thdraw p reflectedabout (origin,(0,u));
  for i:=1 upto round(3+2*mlog(sc)/mlog 2):
    thdraw (0,-(1-0.2i)*u)--(.2u,-(1-0.2(i-1))*u);
  endfor;
  thclean fullcircle scaled 0.6u shifted (0,0.05u);
  thdraw (-0.1732u,-0.05u) -- (0.1732u,0.15u);
  thdraw (0.1732u,-0.05u) -- (-0.1732u,0.15u);
  thdraw (0,-0.15u) -- (0,0.25u);
enddef;

def p_airdraught_summer_UIS (expr pos,theta,sc,al)=
  U:=(.2u,u);
  T:=identity aligned al rotated theta scaled 1 shifted pos;
  pickup PenC;
  thdraw (0,u)--(0,-0.8u);
  p:=(-.2u,.65u){dir 20}..{dir 90}(0,u);
  thdraw p;
  thdraw p reflectedabout (origin,(0,u));
  for i:=1 upto round(3+2*mlog(sc)/mlog 2):
    thdraw (0,-(1-0.2i)*u)--(.2u,-(1-0.2(i-1))*u);
  endfor;
  thclean fullcircle scaled 0.6u shifted (0,0.05u);
  thdraw (-0.1732u,-0.05u) -- (0.1732u,0.15u);
  thdraw (0.1732u,-0.05u) -- (-0.1732u,0.15u);
  thdraw (0,-0.15u) -- (0,0.25u);
  thclean fullcircle scaled 0.3u shifted (0,0.05u);
  thdraw fullcircle scaled 0.2u shifted (0,0.05u);
enddef;


def p_station_fixed_ASF (expr pos)=
    T:=identity shifted pos;
    pickup PenD;
    pair z;
    z:=(0,.2u);
    thclean z -- (z rotated 120) -- (z rotated 240) -- cycle;
    thdraw z -- (z rotated 120) -- (z rotated 240) -- cycle;
    thdraw origin;
enddef;

def p_station_painted_SKBB (expr pos)=
    T:=identity shifted pos;
    pickup PenC;
    thclean fullcircle scaled 0.25u;
    thdraw fullcircle scaled 0.25u;
enddef;

def p_station_natural_ASF (expr pos)=
    T:=identity shifted pos;
    pickup PenD;
    thclean fullcircle scaled .3u;
    thdraw fullcircle scaled .3u;
    thdraw origin;
enddef;

def p_station_temporary_ASF (expr pos)=
    T:=identity shifted pos;
    pickup PenD;
    p:=(-.2u,0)--(.2u,0);
    thdraw p;
    thdraw p rotated 90;
    thclean fullcircle scaled .16u;
    pickup PenC;
    thdraw origin;
enddef;

let p_station_temporary_SKBB = p_station_painted_SKBB;

def p_steps_SKBB (expr pos,r,s,al) =
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.3u,.3u)--(-.3u,.1u)--(-.1u,.1u)--(-.1u,-.1u)--
           (.1u,-.1u)--(.1u,-.3u)--(.3u,-.3u);
enddef;

def p_fixedladder_SKBB (expr pos,r,s,al) =
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.15u,-.4u)--(-.15u,.4u);
    thdraw (.15u,-.4u)--(.15u,.4u);
    thdraw (-.15u,0)--(.15u,0);
    thdraw (-.15u,.2u)--(.15u,.2u);
    thdraw (-.15u,-.2u)--(.15u,-.2u);
enddef;

def p_ropeladder_SKBB (expr pos,r,s,al) =
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (.1u,-.4u)..(.2u,-.2u)..(.1u,.2u)..(.2u,.4u);
    thdraw (-.2u,-.4u)..(-.1u,-.2u)..(-.2u,.2u)..(-.1u,.4u);
    thdraw (-.2u,.2u)--(.1u,.2u);
    thdraw (-.15u,0)--(.15u,0);
    thdraw (-.1u,-.2u)--(.2u,-.2u);
enddef;

def p_bridge_SKBB (expr pos,r,s,al) =
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.3u,.2u)--(-.2u,.1u)--(.2u,.1u)--(.3u,.2u);
    thdraw (-.3u,-.2u)--(-.2u,-.1u)--(.2u,-.1u)--(.3u,-.2u);
enddef;

def p_noequipment_SKBB (expr pos,r,s,al) =
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    thfill (0,-.1u)--(-.05u,.3u)--(.05u,.3u)--cycle;
    thdraw (0,-.2u) withpen PenX;
enddef;

def p_anchor_SKBB (expr pos,r,s,al) =
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    thdraw fullcircle scaled .2u shifted (0.2u,0) withpen PenC;
    begingroup;
      interim linecap:=butt;
      thdraw (-.3u,0)--(.1u,0) withpen PenA;
    endgroup;
    thdraw (.1u,-.4u)--(.1u,.4u) withpen PenD;
enddef;

def p_traverse_SKBB (expr pos,r,s,al) =
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.25u,.05u)..(0,-.08u)..(.25u,.05u);
    pickup pencircle scaled .18u;
    thdraw (-.25u,.05u);
    thdraw (.25u,.05u);
enddef;

def p_rope_SKBB (expr pos,r,s,al) =
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.2u,.2u)..origin..(.1u,.1u)--(.1u,-.4u);
    pickup pencircle scaled .18u;
    thdraw (-.2u,.2u);
    thdraw (.1u,.1u);
enddef;

def p_camp_SKBB (expr pos,r,s,al) =
    U:=(.4u, .5u);
    T:=identity aligned al shifted pos;
    pickup PenC;
    thdraw (-.4u,-.4u)--(0,.5u)--(.4u,-.4u)--cycle;
    pickup PenD;
    thdraw (0,-.4u)--(0,.5u);
enddef;


def p_dig_UIS (expr pos,r,s,al) =
    U:=(.4u, .5u);
    T:=identity aligned al shifted pos;
    thfill ((-.075u,-.5u){down} .. {up}(0.075u, -.5u) -- (0.075u, .15u) -- (0.3u, 0.15u) -- (0.3u, 0.5u) --
    (-.3u, .5u) -- (-.3u, .15u) -- (-.075u, .15u) -- cycle) rotated 45;
enddef;

def p_continuation_UIS(expr pos,theta,sc,al) =
  U:=(.15u,.3u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.1u,.2u){up}..{down}(.1u,.2u)..{down}(0,-.05u);
  pickup PenX;
  thdraw (0,-.2u);
enddef;

def p_station_SKBB(expr pos,mark,txt)(text flags) =
  T:=identity shifted pos;

  if mark=4: p_station_fixed(pos)
  elseif mark=3: p_station_natural(pos)
  elseif mark=2: p_station_painted(pos)
  elseif mark=1: p_station_temporary(pos)
  fi;

  path path_cave;
  path_cave = (-.3u,-.25u) -- (-.2u,-.25u){dir 135} .. (0, .25u) .. {dir 225}(.2u,-.25u) -- (.3u,-.25u);
  for i=flags:
    pickup PenX;
    if i="entrance":
%      thfill fullcircle scaled 1 cm withtransparentcolor tr_blue;
      thdraw path_cave;
%      p_label.urt(txt,pos+(0.4u,0),0,0);
      if not numeric txt:
        p_smartlabel(txt,pos);
      fi;
    elseif i="sink":
      thdraw path_cave cutbefore ((-u,0)--(u,0)) cutafter ((-u,0)--(u,0));
      pickup PenA;
      thdraw (0,-.45u) -- (0,.05u) withcolor blue;
      thdraw (-.15u,-.02u) -- (0,.05u) -- (.15u,-.02u) withcolor blue;
    elseif i="spring":
      thdraw path_cave cutbefore ((-u,0)--(u,0)) cutafter ((-u,0)--(u,0));
      pickup PenA;
      thdraw (0,-.45u) -- (0,.05u) withcolor blue;
      thdraw (-.15u,-.38u) -- (0,-.45u) -- (.15u,-.38u) withcolor blue;
    elseif i="doline":
      thdraw (-.5u,.05u){down}..(0,-0.6u)..{up}(.5u,.05u);
    elseif i="dig":
      thdraw (-.5u,.25u) -- (-.35u,.25u)--(-.23u,-.25u)--(.23u,-.25u)--(.35u,.25u)--(.5u,.25u);
    elseif substring(0,11) of i = "air-draught":
      pickup PenB;
      thdraw ((0,.11u){dir-120} ..{dir-70}(0,0) .. {dir-120}(0,-.11u));
      thdraw ((0,.11u){dir-120} ..{dir-70}(0,0) .. {dir-120}(0,-.11u)) shifted (.11u,0);
      thdraw ((0,.11u){dir-120} ..{dir-70}(0,0) .. {dir-120}(0,-.11u)) shifted (-.11u,0);
    elseif i="continuation":
      if picture(txt):
        picture ATTR__text;
        ATTR__text := txt;
      fi;
      begingroup;
        save T; transform T;
        p_continuation(pos+(0,.25u),0,1,(0,1));
      endgroup;
      if picture(txt):
        save ATTR__text;
      fi;
    elseif i="arch":
      thdraw (-.5u,-.25u)--(-.5u,.25u)--(.5u,.25u)--(.5u,-.25u)..(0,.2u)..cycle;
      thfill (-.5u,-.25u)--(-.5u,.25u)--(.5u,.25u)--(.5u,-.25u)..(0,.2u)..cycle;
    elseif i="overhang":
      thdraw (.2u,-.25u)--(-.2u,-.25u){up}..{right}(.2u,.25u);
    fi;
  endfor;
%  thdraw (0,0) withpen PenX withcolor red;
enddef;

def p_debug (expr col, pen, pos)=
    T:=identity shifted pos;
    thdraw origin withpen pencircle
      scaled if pen=0: 2pt
                 else: 4pt fi
      withcolor if col=-2: (1,.85,0)
           elseif col=-1: black
           elseif col=0: red
           else: blue fi;
enddef;


def p_u(expr pos,theta,sc,al) =
  T:=identity shifted pos;
  thdraw origin withpen pencircle scaled 4pt withcolor red;
enddef;

def p_handrail_SKBB(expr pos,theta,sc,al) =
    tmph := 1 / Scale * 72 / 2.54;  % 1 m height
    U:=(.1u, tmph);
    pickup PenC;
    T:=identity aligned al rotated theta scaled sc shifted pos;
    thdraw (0,0) -- (0,tmph);
    thdraw (0,tmph) withpen pencircle scaled .25u;
enddef;

def p_viaferrata_SKBB(expr pos,r,s,al) =
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.15u,.15u)--(-.15u,.1u)--(.15u,.1u)--(.15u,.15u);
    thdraw (-.15u,-.05u)--(-.15u,-.1u)--(.15u,-.1u)--(.15u,-.05u);
enddef;

def p_stalagmites_UIS(expr pos,theta,sc,al) =
    U:=(.3u, .2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    for i=-1 upto 1:
        T:=identity aligned al rotated theta scaled (sc * 0.7) shifted (pos + (i * .3u, 0));
        thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
        thdraw (0,-.15u) -- (.15u,-.4u);
    endfor;
enddef;

def p_stalactites_UIS(expr pos,theta,sc,al) =
    U:=(.3u, .2u);
    pickup PenC;
    for i=-1 upto 1:
        T:=identity aligned al rotated theta scaled (sc * 0.7) shifted (pos + (i * .3u, 0));
        thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
        thdraw (0,.15u) -- (.15u,.4u);
    endfor;
enddef;

def p_gradient_SKBB (expr pos,theta,sc,al)=
    U:=(.3u,.6u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,-.6u)--(-.3u,.6u);
    thdraw (0,-.6u)--(0,-0.2u);
    thdraw (.3u,-.6u)--(.3u,.6u);
enddef;

def p_pillars_UIS(expr pos,theta,sc,al) =
    U:=(.3u, .2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    for i=-1 upto 1:
        T:=identity aligned al rotated theta scaled (sc * 0.7) shifted (pos + (i * .3u, 0));
        thdraw (0,.15u)--(0,-.15u);
        thdraw (-.15u,-.4u)--(0,-.15u)--(.15u,-.4u);
        thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
    endfor;
enddef;





%%%%% ENDINPUT thPoint %%%%%





%%%%% INPUT thLine %%%%%


%% therion source code
%%
%% This file defines macros for line symbols
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: thLine.mp,v $
%% $Revision: 1.4 $
%%
%% Copyright (C) 2000 Martin Budaj
%%
%% --------------------------------------------------------------------
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

% some definitions

% adjust step according to the length of the path; return at least two steps

vardef adjust_step (expr len, s) =
  if s <= len/2: len / (floor(len / s))
  else: len/2 fi
enddef;

def mark_(expr p,t,l) =
  thdraw (point t of p) --
          ((point t of p) + l * unitvector(thdir(p,t) rotated 90));
enddef;

vardef thdir (expr p,t) =    % 1 * epsilon caused problems in scales < 1:1000
                             % n * epsilon is enough for scale 1:(n*1000)
  if arclength(p)=0:
    hide(thwarning("unable to determine direction on zero-length path"))
    (0,1)
  else:
%  ((direction t-100*epsilon of p) + (direction t+100*epsilon of p)) / 2
   postcontrol (t+1000*epsilon) of p - precontrol (t-1000*epsilon) of p
%  direction t of p
  fi
enddef;

vardef polyline_offset(expr p, amount, direction) =
  % direction should be 90 or -90
  save P;
  path P,R;
  P = punked p;   % convert to polyline
  pair za, zb;
  for i=0 upto length P:
    if i > 0:
      za := unitvector(point i of P - point i-1 of P);      % direction of the previous segment
    else:                       % the first segment
      if cycle P:
        za := unitvector(point length P of P - point (length P)-1 of P);
      else:
        za := unitvector(point 1 of P - point 0 of P);    % za == zb
      fi;
    fi;
    if i < length P:
      zb := unitvector(point i+1 of P - point i of P);    % direction of the next segment
    else:                       % the last segment
      if cycle P:
        % zb is unused as the path is closed by "-- cycle"
      else:
        zb := za;
      fi;
    fi;
    A := 180-(angle(za)-angle(zb));
    R := if i>0: R -- fi
         if (i=length P) and cycle P: cycle else:
         point i of P + amount*unitvector(((za+zb)/2) rotated direction)/abs(sind(A/2)) fi;
  endfor;
  R
enddef;


% walls:

def l_wall_bedrock_UIS (expr P) =
  T:=identity;
  pickup PenA;
  thdraw P;
enddef;

def l_wall_sand_SKBB (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.1u);
  pickup PenB;
  forever:
    t := arctime cas of P;
    thdraw ((point t of P) + (uniformdeviate 1) * .4u
            * unitvector(thdir(P,t) rotated -90));
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
  endfor;
  pickup PenA;
  thdraw P;
enddef;

def l_wall_pebbles_SKBB (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .35u);
  pickup PenC;
  q:=superellipse((.2u,0),(0,.1u),(-.2u,0),(0,.-.1u),.75);
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw q randomized (u/20) rotated (angle(thdir(P,t)) + (normaldeviate*40)) shifted point t of P;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;

def l_wall_clay_SKBB (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .5u);
  pickup PenC;
  q := (-0.15u,0){up}..{down}origin..{up}(0.15u,0);
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw q shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
  pickup PenA;
  thdraw P;
enddef;

def l_wall_debris_SKBB (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .4u);
  pickup PenC;
%  q := ((-.1u,-.15u)--(.2,.03u)--(-.2u,.15u)--cycle) scaled 1.5;
  q := ((-.2u,-.1u)--(.2u,-.1u)--(0,.2u)--cycle) scaled 1.1;
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw q randomized (u/10) rotated uniformdeviate (360) shifted point t of P;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;

def l_wall_blocks_SKBB (expr P) =
%  pickup PenD;
%  draw P withcolor red;

  T:=identity;
  cas := 0;
  dlzka := arclength P;
if dlzka > 0:
  mojkrok:=adjust_step(dlzka, 1.5u);
  pickup PenA;
  forever:
    t1 := arctime (cas + mojkrok*1/10) of P;
    t2 := arctime (cas + mojkrok*9/10) of P;
    q := ((point t1 of P) + .4u * unitvector(thdir(P,t1) rotated -90)) --
         (subpath (t1,t2) of P) --
         ((point t2 of P) + .4u * unitvector(thdir(P,t2) rotated -90));
    thdraw q randomized (u/6);
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
fi;
enddef;

def l_wall_ice_SKBB (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .5u);
  pickup PenC;
  p := (-.1u,0)--(.1u,0);
  q := (0,-.1u)--(0,.1u);
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw p shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
    thdraw q shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
  pickup PenA;
  thdraw P;
enddef;

def l_wall_underlying_UIS (expr P) =
  T:=identity;
  pickup PenA;
  thdraw P dashed evenly scaled optical_zoom;
enddef;

def l_wall_unsurveyed_SKBB (expr P) =
  T:=identity;
  pickup PenC;
  thdraw P;
enddef;

def l_wall_presumed_UIS (expr P) =
  T:=identity;
  pickup PenA;
  thdraw P dashed evenly scaled (2*optical_zoom);
enddef;

% other line symbols

def l_pit_UIS (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.25u);
  pickup PenD;
  forever:
    t := arctime cas of P;
    mark_ (P,t,0.2u);
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
  endfor;
  pickup PenC;
  thdraw P;
enddef;

let l_floorstep_UIS = l_pit_UIS;

def l_overhang_SKBB (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.3u);
  pickup PenC;
  t1:=0;
  forever:
    t := arctime (cas + mojkrok/2) of P;
    t2 := arctime (cas + mojkrok) of P;
    thfill (subpath (t1,t2) of P) --
      ((point t of P) + .3u * unitvector(thdir(P,t) rotated 90)) --
      cycle;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
    t1:=t2;
  endfor;
  thdraw P;
enddef;


def l_chimney_UIS (expr P) =
  T:=identity;
  pickup PenC;
  thdraw P dashed evenly scaled optical_zoom;
enddef;

def l_ceilingstep_SKBB (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.8u);
  pickup PenC;
  forever:
    t1 := arctime (cas + mojkrok*1/5) of P;
    t  := arctime (cas + mojkrok/2) of P;
    t2 := arctime (cas + mojkrok*4/5) of P;
    thdraw (subpath (t1,t2) of P);
    mark_ (P,t,0.2u);
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;

def l_ceilingmeander_SKBB (expr P) =
  pair Pp;
  pair Pd;
  pair Pv;
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.8u);
  pickup PenC;
  forever:
    t  := arctime (cas + mojkrok/2) of P;
    Pp := (point t of P);
    Pd := unitvector(thdir(P,t));
    Pv := Pd rotated 90;
    thdraw (Pp + 0.1u * Pv) --
          (Pp + 0.2u * Pv);
    thdraw (Pp + 0.2u * Pv + 0.2u * Pd) --
          (Pp + 0.2u * Pv - 0.2u * Pd);
    thdraw (Pp - 0.1u * Pv) --
          (Pp - 0.2u * Pv);
    thdraw (Pp - 0.2u * Pv + 0.2u * Pd) --
          (Pp - 0.2u * Pv - 0.2u * Pd);
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;


%Bruce Mutton 2012.06.16 uses general code for l_ceilingmeander_SKBB defined in therion source code by Martin Budaj 5.3.9
% but ticks on outside (rock) side of lines
def l_ceilingmeander_UIS (expr P) =
  pair Pp;
  pair Pd;
  pair Pv;
  T:=identity;
  cas := 0;                           % cursor to step along path
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.8u);  % symbol length nudged to be multiple of path length
  pickup PenC;
  forever:
    t  := arctime (cas + mojkrok/2) of P;
    Pp := (point t of P);
    Pd := unitvector(thdir(P,t));
    Pv := Pd rotated 90;
    thdraw (Pp + 0.2u * Pv) --
          (Pp + 0.3u * Pv);              % add 0.1u to each moves ticks outside
    thdraw (Pp + 0.2u * Pv + 0.2u * Pd) --
          (Pp + 0.2u * Pv - 0.2u * Pd);
    thdraw (Pp - 0.2u * Pv) --
          (Pp - 0.3u * Pv);              % subtract 0.1u to each moves ticks outside
    thdraw (Pp - 0.2u * Pv + 0.2u * Pd) --
          (Pp - 0.2u * Pv - 0.2u * Pd);
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3);  % for rounding errors
  endfor;
enddef;

let l_ceilingmeander_NZSS = l_ceilingmeander_UIS;

%Bruce Mutton 2012.06.16 uses general code for l_ceilingstep_SKBB defined in therion source code by Martin Budaj 5.3.9
% but ticks on righthand (rock) side of line
def l_ceilingstep_UIS (expr P) =
  T:=identity;
  cas := 0;                            % cursor to step along path
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.8u);   % symbol length nudged to be multiple of path length
  pickup PenC;
  forever:
    t1 := arctime (cas + mojkrok*1/5) of P;
    t  := arctime (cas + mojkrok/2) of P;
    t2 := arctime (cas + mojkrok*4/5) of P;
    thdraw (subpath (t1,t2) of P);
    mark_ (P,t,-0.2u);                  % change sign to -0.2u
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;

let l_ceilingstep_NZSS = l_ceilingstep_UIS;

%Bruce Mutton 2012.06.10 uses general code for l_pit_UIS defined in therion source code by Martin Budaj 5.3.9
% dots on righthand (rock) side of line spaced 0.2u, 0.2u same as floor-step ticks
def l_chimney_NZSS (expr P) =
	T:=identity;
	cas := 0;                            % cursor to step along path
	dlzka := arclength P;
	mojkrok:=adjust_step(dlzka, 0.25u);  % symbol length nudged to be multiple of path length
	q:= (0.20u,-0.20u) -- (0.21u,-0.21u);         % dot

	pickup PenC;  %2nd thinnest pen
	forever:
	  t := arctime cas of P;
	thdraw q rotated angle(thdir(P,t)) shifted (point t of P ); % draw dots
	cas := cas + mojkrok;
	  exitif cas > dlzka + (mojkrok / 3); % for rounding errors
	endfor;
	pickup PenB;   %2nd thickest pen
	thdraw P;      %continuous line
enddef;

%Bruce Mutton 2010.06.20 uses general code and adjust_step defined in therion source code by Martin Budaj
%for Therion 5.3.8
def l_wall_presumed_NZSS (expr P) =
	T:=identity;
	cas := 0;                                 % cursor to step along path
	dlzka := arclength P;
	mojkrok:=adjust_step(dlzka, 1.5u);        % symbol length nudged to be multiple of path length
	q  := (-0.2u,-0.4u)--(0,0)--(0.2u,-0.4u); % define v shape
	forever:
	  t1 := arctime (cas + mojkrok*1/5) of P;
	  t  := arctime (cas + mojkrok/2) of P;
	  t2 := arctime (cas + mojkrok*4/5) of P;
		pickup PenA;                          % thick
	thdraw (subpath (t1,t2) of P);          % dash
	  pickup PenC;                          % thin
	  thdraw q rotated angle(thdir(P,t)) shifted (point t of P ); % v shape

	  cas := cas + mojkrok;
	  exitif cas > dlzka - (2*mojkrok/3);     % for rounding errors
	endfor;
enddef;

def l_floormeander_SKBB (expr P) =
  pair Pp;
  pair Pd;
  pair Pv;
  pair PPp;
  pair PPd;
  pair PPv;

  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.25u);
  pickup PenC;
  forever:
    t := arctime cas of P;
    Pp := (point t of P);
    Pd := unitvector(thdir(P,t));
    Pv := Pd rotated 90;
    thdraw (Pp + 0.1u * Pv) --
          (Pp + 0.2u * Pv);
    thdraw (Pp - 0.1u * Pv) --
          (Pp - 0.2u * Pv);
    if cas > 0:
      thdraw (PPp + 0.2u * PPv) --
          (Pp + 0.2u * Pv);
      thdraw (PPp - 0.2u * PPv) --
          (Pp - 0.2u * Pv);
    fi;
    PPp := Pp;
    PPd := Pd;
    PPv := Pv;
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
  endfor;
enddef;

boolean alw_perpendicular;

def l_slope_SKBB (expr P,S)(text Q) =
%show Q;
  T:=identity;
  numeric dirs[];
  numeric lengths[];
  for i=Q:
    dirs[redpart i]:=greenpart i;
    lengths[redpart i]:=bluepart i;
  endfor;


  li:=length(P); % last

  alw_perpendicular:=true;

  for i=0 upto li:
    if unknown dirs[i]: dirs[i]:=-1;
    else:
      if dirs[i]>-1:
        dirs[i]:=((90-dirs[i]) - angle(thdir(P,i))) mod 360;
        alw_perpendicular:=false;
      fi;
    fi;
    if unknown lengths[i]: lengths[i]:=-1; fi;
  endfor;

%for i=0 upto li: show dirs[i]; endfor;

  ni:=0; % next
  pi:=0; % previous

  for i=0 upto li:
    d:=dirs[i];
    if d=-1:
      if (i=0) or (i=li):
        dirs[i] := angle(thdir(P,i) rotated 90) mod 360;
	pi:=i;
      else:
        if ni<=i:
	  for j=i upto li:
            ni:=j;
	    exitif dirs[j]>-1;
	  endfor;
	fi;
	w:=arclength(subpath(pi,i) of P) /
	   arclength(subpath(pi,ni) of P);
	dirs[i]:=w[dirs[pi],dirs[ni]];
%        if (dirs[i]-angle(thdir(P,i))) mod 360>180:
%          dirs[i]:=w[dirs[ni],dirs[pi]];
%	  message("*******");
%        fi;
     fi;
    else:
      pi:=i;
    fi;
  endfor;

%for i=0 upto li: show dirs[i]; endfor;

  ni:=0; % next
  pi:=0; % previous

  for i=0 upto li:
    l:=lengths[i];
    if l=-1:
      if (i=0) or (i=li):
        lengths[i] := 1cm; % should never happen!
	thwarning("slope width at the end point not specified");
	pi:=i;
      else:
        if ni<=i:
	  for j=i+1 upto li:
            ni:=j;
	    exitif lengths[j]>-1;
	  endfor;
	fi;
	w:=arclength(subpath(pi,i) of P) /
	   arclength(subpath(pi,ni) of P);
	lengths[i]:=w[lengths[pi],lengths[ni]];
	pi:=i;
      fi;
    else:
      pi:=i;
    fi;
  endfor;

% for i=0 upto li: show lengths[i]; endfor;

  T:=identity;
  boolean par;
  offset:=0;
  dlzka := (arclength P);
  if dlzka>3u:
    offset := 0.3u;
  elseif dlzka>u:
    offset := 0.1u;
  fi;
  dlzka:=dlzka-2offset;
  cas := offset;
  mojkrok:=adjust_step(dlzka,1.4u) / 2;
  pickup PenD;
  par := false;
  forever:
    t := arctime cas of P;
    if t mod 1>0:  % not a key point
      w := (arclength(subpath(floor t,t) of P) /
            arclength(subpath(floor t,ceiling t) of P));
      if alw_perpendicular:
        a := 90;
      else:
        a := w[dirs[floor t],dirs[ceiling t]];
      fi;
      l := w[lengths[floor t],lengths[ceiling t]];
    else:
      if alw_perpendicular:
        a := 90;
      else:
        a:= dirs[t];
      fi;
      l:=lengths[t];
    fi;

    a := a + angle(thdir(P,t));

    thdraw (point t of P) --
      ((point t of P) + if par: 0.333 * fi l * unitvector(dir(a)));
    cas := cas + mojkrok;
    par := not par;
    exitif cas > dlzka + offset + 0.1mm;  % for rounding errors
  endfor;
  if S = 1: pickup PenC; draw P fi;
%pickup pencircle scaled 3pt;
%for i=0 upto li: draw point i of P; endfor;
enddef;


def l_slope_BCRA (expr P,S)(text Q) =
%show Q;
  T:=identity;
  numeric dirs[];
  numeric lengths[];
  for i=Q:
    dirs[redpart i]:=greenpart i;
    lengths[redpart i]:=bluepart i;
  endfor;


  li:=length(P); % last

  alw_perpendicular:=true;

  for i=0 upto li:
    if unknown dirs[i]: dirs[i]:=-1;
    else:
      if dirs[i]>-1:
        dirs[i]:=((90-dirs[i]) - angle(thdir(P,i))) mod 360;
        alw_perpendicular:=false;
      fi;
    fi;
    if unknown lengths[i]: lengths[i]:=-1; fi;
  endfor;

%for i=0 upto li: show dirs[i]; endfor;

  ni:=0; % next
  pi:=0; % previous

  for i=0 upto li:
    d:=dirs[i];
    if d=-1:
      if (i=0) or (i=li):
        dirs[i] := angle(thdir(P,i) rotated 90) mod 360;
	pi:=i;
      else:
        if ni<=i:
	  for j=i upto li:
            ni:=j;
	    exitif dirs[j]>-1;
	  endfor;
	fi;
	w:=arclength(subpath(pi,i) of P) /
	   arclength(subpath(pi,ni) of P);
	dirs[i]:=w[dirs[pi],dirs[ni]];
%        if (dirs[i]-angle(thdir(P,i))) mod 360>180:
%          dirs[i]:=w[dirs[ni],dirs[pi]];
%	  message("*******");
%        fi;
     fi;
    else:
      pi:=i;
    fi;
  endfor;

%for i=0 upto li: show dirs[i]; endfor;

  ni:=0; % next
  pi:=0; % previous

  for i=0 upto li:
    l:=lengths[i];
    if l=-1:
      if (i=0) or (i=li):
        lengths[i] := 1cm; % should never happen!
	thwarning("slope width at the end point not specified");
	pi:=i;
      else:
        if ni<=i:
	  for j=i+1 upto li:
            ni:=j;
	    exitif lengths[j]>-1;
	  endfor;
	fi;
	w:=arclength(subpath(pi,i) of P) /
	   arclength(subpath(pi,ni) of P);
	lengths[i]:=w[lengths[pi],lengths[ni]];
	pi:=i;
      fi;
    else:
      pi:=i;
    fi;
  endfor;

% for i=0 upto li: show lengths[i]; endfor;

  T:=identity;
  boolean par;
  offset:=0;
  dlzka := (arclength P);
  if dlzka>3u:
    offset := 0.3u;
  elseif dlzka>u:
    offset := 0.1u;
  fi;
  dlzka:=dlzka-2offset;
  cas := offset;
  mojkrok:=adjust_step(dlzka,1.4u) / 2;
  pickup PenD;
  par := false;
  forever:
    t := arctime cas of P;
    if t mod 1>0:  % not a key point
      w := (arclength(subpath(floor t,t) of P) /
            arclength(subpath(floor t,ceiling t) of P));
      if alw_perpendicular:
        a := 90;
      else:
        a := w[dirs[floor t],dirs[ceiling t]];
      fi;
      l := w[lengths[floor t],lengths[ceiling t]];
    else:
      if alw_perpendicular:
        a := 90;
      else:
        a:= dirs[t];
      fi;
      l:=lengths[t];
    fi;

    a := a + angle(thdir(P,t));

    if par:
      thfill (point t of P) + mojkrok/2.5 * unitvector(dir(a+90))--
        ((point t of P) + l * unitvector(dir(a))) --
        (point t of P) + mojkrok/2.5 * unitvector(dir(a-90)) -- cycle;
    fi;
    cas := cas + mojkrok;
    par := not par;
    exitif cas > dlzka + offset + 0.1mm;  % for rounding errors
  endfor;
enddef;


def l_contour_UIS(expr P)(text txt) =
  T:=identity;
  pickup PenD;
  thdraw P;
  for pnt=txt:
    if pnt=-2:
      mark_(P,arctime(arclength(P)/2) of P, 0.2u);
    elseif pnt>=0:
      mark_(P,pnt,0.2*u);
    fi;
    exitif pnt<0;
  endfor;
enddef;

def l_contour_SKBB(expr P)(text txt) =
  T:=identity;
  pickup PenD;
  thdraw P;
  for pnt=txt:
    if (pnt=-2) or (pnt=-1):
      mark_(P,arctime(arclength(P)/2) of P, 0.2u);
    elseif pnt>=0:
      mark_(P,pnt,0.2*u);
    fi;
    exitif pnt<0;
  endfor;
enddef;

def l_rockborder_UIS (expr P) =
  T:=identity;
  pickup PenC;
  if cycle P: thclean P fi;
  thdraw P;
enddef;

def l_rockedge_UIS (expr P) =
  T:=identity;
  pickup PenD;
  thdraw P;
enddef;

def l_border_visible_SKBB (expr Path) =
  T:=identity;
  pickup PenC;
  draw Path;
enddef;

def l_border_temporary_SKBB (expr Path) =
  T:=identity;
  pickup PenC;
  draw Path dashed evenly scaled optical_zoom;
enddef;

def l_flowstone_UIS (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .7u);
  if (cycle P) and (dlzka < 3.5u):   % make at least 5 curls on a cyclic path
    mojkrok := dlzka/5;
  fi;
  pickup PenC;
  t1:=0;
  forever:
    t2 := arctime (cas + mojkrok) of P;
    thdraw (point t1 of P){dir (angle(thdir(P,t1)) + 60)} ..
           {dir (angle(thdir(P,t2)) - 60)}(point t2 of P);
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
    t1:=t2;
  endfor;
enddef;


def l_moonmilk_UIS (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .3u);
  pickup PenC;
  t1:=0;
  forever:
    t2 := arctime (cas + mojkrok) of P;
    thdraw (point t1 of P){dir (angle(thdir(P,t1)) + 80)} ..
           {dir (angle(thdir(P,t2)) - 80)}(point t2 of P);
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
    t1:=t2;
  endfor;
enddef;


def l_survey_surface_SKBB (expr P) =
  T:=identity;
  thdrawoptions(dashed withdots scaled (0.2 * optical_zoom) withpen PenC);
  thdraw P;
  thdrawoptions();
enddef;

def l_survey_cave_SKBB (expr P) =
  T:=identity;
  pickup PenC;
  if ATTR__scrap_centerline:
    thdraw P;
  else:
    PolygonLine:=.8u;
    pair zz[];
    for t = 0 upto length P - 1:
      zz1 := point t of P;
      zz2 := point t+1 of P;
      if length (zz2-zz1) > 2*PolygonLine:
        thdraw zz1 -- zz1 + PolygonLine * unitvector(zz2 - zz1);
        thdraw zz2 -- zz2 + PolygonLine * unitvector(zz1 - zz2);
      else:
        thdraw zz1 -- zz2;
      fi;
    endfor;
  fi;
enddef;

def l_survey_cave_UIS (expr P) =
  T:=identity;
  pair zz[];
  pickup PenC;
  for t = 0 upto length P - 1:
    zz1 := point t of P;
    zz2 := point t+1 of P;
    draw zz1 -- zz2;
  endfor;
enddef;

def l_waterflow_permanent_UIS (expr Path) =
  path ppp;
  T:=identity;
  cas := 0;
  dlzka := arclength Path;
  mojkrok:=adjust_step(dlzka, 0.5u);
    pickup PenD;
    vardef azim = 50 + 15*normaldeviate enddef;
    az1 := azim;
    sgn := 1;
    ppp := point 0 of Path;
    forever:
        t1 := arctime cas of Path;
        t2 := arctime (cas+mojkrok) of Path;
        if cas+1.1*mojkrok > dlzka:
            az2 := 0;
        else:
            az2 := azim;
        fi;
        d1 := angle(thdir(Path,t1)) + sgn * az1;
        d2 := angle(thdir(Path,t2)) - sgn * az2;
        ppp := ppp & (point t1 of Path){dir d1} .. {dir d2}(point t2 of Path);
        az1 := az2;
        sgn := -1 * sgn;
        cas := cas + mojkrok;
        exitif cas > dlzka + mojkrok/3;     % for rounding errors
    endfor;
%    drawarrow ppp;
    thdraw ppp;
    thdrawoptions();
    oldahlength:=ahlength;
    ahlength:=ahlength*optical_zoom;
    thdraw arrowhead ppp;
    thfill arrowhead ppp;
    ahlength:=oldahlength;
enddef;

def l_waterflow_intermittent_SKBB (expr Path) =
  thdrawoptions(dashed evenly scaled optical_zoom);
  l_waterflow_permanent_UIS (Path);
  thdrawoptions();
enddef;

def l_waterflow_conjectural_SKBB (expr Path) =
  thdrawoptions(dashed withdots scaled (0.5 * optical_zoom) withpen PenB);
  l_waterflow_permanent_UIS (Path);
  thdrawoptions();
enddef;

def l_invisible (expr P) =
enddef;

def l_undefined (expr P) =
  T:=identity;
  pickup PenC;
  thdraw P withcolor red;
  thwarning("undefined line symbol used");
enddef;

% Q = 0 -- no arrows
%     1 -- end
%     2 -- begin
%     3 -- both

def l_arrow_SKBB (expr P, Q) =
  T:=identity;
  pickup PenC;
  thdraw P;
  p := (-.1u,-.25u)--(0,0)--(.1u,-.25u);
  if odd Q:
    draw p rotated (angle(thdir(P,0))+90) shifted (point 0 of P);
  fi;
  if Q>1:
    draw p rotated (angle(thdir(P,length P))-90)
         shifted (point infinity of P);
  fi;
enddef;

def l_mapconnection_SKBB (expr P) =
  thdrawoptions(dashed withdots scaled (0.5 * optical_zoom) withpen PenB);
  l_arrow_SKBB(P,3);
  thdrawoptions();
enddef;


def l_section_SKBB (expr P)(text txt) =
  T:=identity;
  path Q; Q = punked P;
  pickup PenC;
  for t = 0 upto length P - 1:
    pair zz[];
    zz1 := point t of P;
    zz2 := point t+1 of P;
    zz3 := postcontrol t of P;
    zz4 := precontrol t+1 of P;
    if (length(zz3-1/3[zz1,zz2]) > 0.1pt) or
       (length(zz4-2/3[zz1,zz2]) > 0.1pt):
      zz5 = whatever[zz1,zz2];
      (zz3-zz5) = whatever * (zz1-zz2) rotated 90;
      draw zz1--zz5;
      zz6 = whatever[zz1,zz2];
      (zz4-zz6) = whatever * (zz1-zz2) rotated 90;
      draw zz2--zz6;
    else:
      draw zz1--zz2;
    fi;
  endfor;
  for pnt=txt:
    if pnt=-1:
    else:
      T:=identity rotated angle(thdir(Q,pnt)) shifted (point pnt of Q);
      pickup PenC;
      thdraw (0,0)--(0,.8u);
      thdraw (-.1u,.55u)--(0,.8u)--(.1u,.55u);
    fi;
    exitif pnt=-1;
  endfor;
enddef;

let l_border_invisible = l_invisible;
let l_wall_invisible = l_invisible;

def l_debug (expr col, pen, P) =
  T:=identity;
  pickup if pen=0: PenD else: PenB fi;
  thdraw P
    withcolor if col=-2: (1,.85,0)
          elseif col=-1: black
           elseif col=0: red
                   else: blue fi;
enddef;


def l_u (expr P) =
  T:=identity;
  pickup PenA;
  thdraw P withcolor red;
enddef;


def l_gradient_UIS (expr P) =
  T:=identity;
  pickup PenC;
  thdraw P;
  p:=(-.15u,-.4u)--(0,0)--(.15u,-.4u)--cycle;
  thfill (p rotated (angle(thdir(P,length P))-90)
         shifted (point infinity of P));
  thdraw (p rotated (angle(thdir(P,length P))-90)
         shifted (point infinity of P));
enddef;

def l_gradient_BCRA (expr P) =
  T:=identity;
  pickup PenC;
  for t = 0 upto length P - 1:
    pair zz[];
    zz1 := point t of P;
    zz2 := point t+1 of P;
    zz3 := unitvector(zz2 - zz1);
    thfill zz1 + u/3 * zz3 + .25u * (zz3 rotated 90) --
           zz2 - u/3 * zz3 --
	   zz1 + u/3 * zz3 + .25u * (zz3 rotated -90) -- cycle;
  endfor;
enddef;


def l_rope_SKBB (expr P, show_anchors, show_rebelays) =
  T:=identity;
  pickup PenC;
  if not show_rebelays:
    draw P;
  else:
    d:=0.5u;
    for i:=0 upto (length P - 2):
      x1 := xpart point i of P;
      y1 := ypart point i of P;
      x2 := xpart point i+1 of P;
      y2 := ypart point i+1 of P;

      dx1:=x1; dy1:=y1; x1:=0; y1:=0; x2:=x2-dx1; y2:=y2-dy1;
      if y2 > y1:
        y3 := y1 - d;
        x3 := x1 + (x2-x1)*sqrt(d)/(sqrt(d)+sqrt(y2-y1+d));
      else:
        y3 := y2 - d;
        x3 := x1 + (x2-x1)*sqrt(y1-y2+d)/(sqrt(d)+sqrt(y1-y2+d));
      fi;
      numeric a,b,c;
      a*x1/10*x1 + b/10*x1 + c/10 = y1/10;
      a*x2/10*x2 + b/10*x2 + c/10 = y2/10;
      a*x3/10*x3 + b/10*x3 + c/10 = y3/10;
      draw (x1+dx1,y1+dy1)
      for t = x1 step (x2-x1)/20 until x2+10*epsilon:
        -- (t+dx1,a*t*t+b*t+c+dy1)
      endfor;
    endfor;
    pair x;
    x = point (length P)-1 of P + whatever * down;
    x = point (length P) of P + whatever * right;
    draw point (length P)-1 of P -- x;
  fi;
  if show_anchors:
    for i:=0 upto length P if show_rebelays: -1 fi:
      thdraw point i of P withpen pencircle scaled 0.25u;
    endfor;
  fi;
enddef;

def l_border_presumed_SKBB (expr Path) =
  T:=identity;
  pickup PenC;
  draw Path dashed evenly scaled (0.25 * optical_zoom);
enddef;

def l_steps_SKBB (expr P) =
 if known ATTR_c: c := scantokens ATTR_c; else: c := 2; fi;
 if ATTR__elevation:
   if (c < 2):
     thwarning("Invalid stairs definition (c<2)");
     pickup PenA;
     draw P withcolor red;
   else:
     path PP;
     if (ypart point 0 of P) < (ypart point length P of P):
       PP := P;
     else:
       PP := reverse P;
     fi;
     path p;
     for j:=0 upto ((length PP) - 1):
       p := (point j of PP) -- (point (j + 1) of PP);
       c := ceiling(abs((ypart point 0 of p) - (ypart point length p of p)) / (0.2 / Scale * 72 / 2.54));  % 20 cm height
       if (c < 2): c:=2 fi;
       pair cp;
       cp = point length p of p - point 0 of p;
       dx := (xpart cp) / c;
       dy := (ypart cp) / c;
       cp := point 0 of p;
       for i:= 0 upto c - 1:
         l_border_visible(cp -- cp + (0,dy) -- cp + (dx,dy));
         cp := cp + (dx, dy);
       endfor;
       %draw P;
     endfor;
   fi;
 else:
   if known ATTR_l: l := scantokens ATTR_l; else: l := (length(P)-2)/2; fi;
   if ((length(P) < 4) or (c < 2)) or ((odd length P) and (not known ATTR_l)):
     thwarning("Invalid stairs definition" if c<2: &" (c<2)" fi);
     pickup PenA;
     draw P withcolor red;
   else:
     path p, q;
     p = subpath (1, 1+l) of P;
     q = reverse subpath (l+2, length(P)) of P;
     lp := arclength(p);
     lq := arclength(q);
     for i=1 upto c:
       l_border_visible(point(arctime ((i-1)/(c-1)*lp) of p) of p -- point(arctime ((i-1)/(c-1)*lq) of q) of q);
     endfor;
     l_border_visible(p);
     l_border_visible(q);
     drawoptions(withcolor 0.3*white);
     %p_label(decimal c, point 0.5 of P, 0, 6);
     drawoptions();
   fi;
 fi;
enddef;

def l_handrail_SKBB (expr P) =
    if ATTR__elevation:
      T:=identity;
      cas := 0;
      dlzka := arclength P;
      mojkrok:=adjust_step(dlzka, 1u);
      pickup PenD;
      pair tmppoint;
      tmph := 1 / Scale * 72 / 2.54;  % 1 m height
      tmppoint:=(point 0 of P) +(0,tmph);
      forever:
        t := arctime cas of P;
        draw point t of P -- (point t of P)+(0,tmph) withpen PenD;
        if cas > 0:
          draw tmppoint -- (point t of P)+(0,tmph) withpen PenC;
          tmppoint := (point t of P)+(0,tmph);
        fi;
        cas := cas + mojkrok;
        exitif cas > dlzka + (mojkrok / 3); % for rounding errors
      endfor;
    else:
      T:=identity;
      cas := 0;
      pair coord;
      sq_size:=0.12u;
      dlzka := arclength P;
      mojkrok:=adjust_step(dlzka, u);
      pickup PenD;
      forever:
        t := arctime cas of P;
        coord := point t of P;
        thfill coord+(-sq_size,-sq_size)--coord+(sq_size,-sq_size)--coord+(sq_size,sq_size)--coord+(-sq_size,sq_size)--cycle;
        cas := cas + mojkrok;
        exitif cas > dlzka + (mojkrok / 3); % for rounding errors
      endfor;
      pickup PenC;
      thdraw P;
    fi;
enddef;

def l_fixedladder_SKBB (expr Q) =
  % TODO: support side view in elevation (front view could be the same as in the plan view)
  T:=identity;
  path P, P_left, P_right;
  P := punked Q;     % ensure that there is no bezier curve
  pair p_tmp, za, zb;
  len := arclength P;
  dt:=adjust_step(len, 0.3u);
  t := dt/2;
  wdth := 0.25u;     % half-width of the ladder
  pickup PenC;
  % draw the steps
  forever:
    p_tmp := point arctime t of P of P;
    draw p_tmp+wdth*unitvector(thdir(P,arctime t of P) rotated -90) --
         p_tmp+wdth*unitvector(thdir(P,arctime t of P) rotated  90);
    t := t + dt;
    exitif t > len + 10*epsilon;
  endfor;
  draw polyline_offset(P,wdth, 90);
  draw polyline_offset(P,wdth,-90);
enddef;

def l_ropeladder_SKBB (expr P) =
  pickup PenD;
  draw P withcolor red;
enddef;

def l_viaferrata_SKBB (expr P) =
  pickup PenD;
  draw P withcolor red;
enddef;




%%%%% ENDINPUT thLine %%%%%





%%%%% INPUT thArea %%%%%


%% therion source code
%%
%% This file defines tiling patterns
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: thPatterns.mp,v $
%% $Revision: 1.6 $
%%
%% Copyright (C) 2000-2004 Martin Budaj
%%
%% --------------------------------------------------------------------
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

if unknown a_water_UIS: else: endinput fi;

% patterns

beginpattern(pattern_water_UIS);
    draw origin--10up withpen pensquare scaled (0.02u);
    patternxstep(.18u);
    patterntransform(identity rotated 45);
endpattern;

beginpattern(pattern_sump_UIS);
    draw origin--(0,.25u) withpen pensquare scaled (0.02u);
    draw origin--(.25u,0) withpen pensquare scaled (0.02u);
    patterntransform(identity rotated 45);
endpattern;

beginpattern(pattern_sand_UIS);
    pickup PenC;
    draw (0.2u,.3u);
    draw (0.35u,.7u);
    draw (0.6u,.5u);
    draw (0.8u,.1u);
endpattern;

beginpattern(pattern_debris_SKBB);
    pickup PenC;
    p:=(-.15u,0)--(.15u,0);
    draw p rotated -40 shifted (.2u,.3u);
    draw p rotated 70 shifted (.9u,1.5u);
    draw p rotated 20 shifted (1.5u,.8u);
%    draw p rotated 95 shifted (.9u,.8u);
endpattern;


beginpattern(pattern_moonmilk_SKBB);
    pickup PenC;
    p:=(-.5u,0){down} .. {up}(-.1666u,0){down}..
        {up}(.1666u,0){down} .. {up}(.5u,0);
    draw p;
    draw p shifted (0.5u,0.3u);
    patternxstep(1.0u);
    patternystep(0.6u);
endpattern;


beginpattern(pattern_flowstone_ASF);
    pickup PenC;
    p:=(-.35u,0){dir -60} .. {dir 60}(0.35u,0);
    draw p;
    draw p shifted (0.35u,0.4u);
    patternxstep(u);
    patternystep(0.8u);
endpattern;


beginpattern(pattern_empty);
  patternbbox(0,0,10,10);
  patternstep(10,10);
endpattern;

% symbols

def a_water_UIS (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_water_UIS;
enddef;

def a_sump_UIS (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_sump_UIS;
enddef;


def a_flowstone_ASF (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_flowstone_ASF;
enddef;


def a_moonmilk_SKBB (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_moonmilk_SKBB;
enddef;



def a_sand_UIS (expr p) =
  T:=identity;
%  thclean p;
  pickup PenC;
  path q; q = bbox p;
  picture tmp_pic;
  tmp_pic := image(
    for i = xpart llcorner q step 1u until xpart urcorner q:
      for j = ypart llcorner q step 1u until ypart urcorner q:
        draw origin shifted ((i,j) randomized 0.7u) withpen PenC;
      endfor;
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_debris_UIS (expr Path) =
  T:=identity;
%  thclean Path;
  thfill Path withpattern pattern_debris_SKBB;
enddef;


def a_bedrock_SKBB (expr Path) =
  T:=identity;
  thclean Path;
enddef;


% used to export centerline LRUD envelope for maps created from surveys

def a_dimensions_SKBB (expr Path) =
  T:=identity;
  thclean Path;
enddef;


def a_debris_SKBB (expr p) =
  T:=identity;
%  thclean p;
  pickup PenC;
  path q; q = bbox p;
  picture tmp_pic;
  tmp_pic := image(
    for i = xpart llcorner q step 1u until xpart urcorner q:
      for j = ypart llcorner q step 1u until ypart urcorner q:
        draw ((-.2u,0)--(.2u,0))
             rotated uniformdeviate(360)
             shifted ((i,j) randomized 0.6u) withpen PenC;
      endfor;
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_clay_SKBB (expr p) =
  T:=identity;
  pickup PenC;
  path q, qq; q = bbox p;
  picture tmp_pic;
  tmp_pic := image(
    for i = xpart llcorner q step 1.5u until xpart urcorner q:
      for j = ypart llcorner q step 1.5u until ypart urcorner q:
        qq := ((-.25u,0){up}..origin{down}..{up}(0.25u,0)) randomized (u/15)
             shifted ((i,j) randomized 1.3u);
	if xpart (p intersectiontimes qq) < 0:
	  thdraw qq;
	fi;
      endfor;
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_ice_SKBB (expr p) =
  T:=identity;
  pickup PenC;
  path q; q = bbox p;
  picture tmp_pic, tmp_ice;
  pair z;
  tmp_ice := image (
    draw (-.2u,0)--(.2u,0);
    draw (0,-.2u)--(0,.2u);
  );
  tmp_pic := image(
    for i = xpart llcorner q step 1.5u until xpart urcorner q:
      for j = ypart llcorner q step 1.5u until ypart urcorner q:
        z := ((i,j) randomized 1.3u);
	if xpart (p intersectiontimes ((bbox tmp_ice) shifted z)) < 0:
	  draw tmp_ice shifted z;
	fi;
      endfor;
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;


def a_snow_SKBB (expr P) =
  T:=identity;
  pickup PenC;
  path q; q = bbox P;
  picture tmp_pic, tmp_sn;
  pair z;
  tmp_sn := image(
    pickup PenC;
    p := origin--(0,.2*u);
    draw p; draw p rotated (60); draw p rotated (120);
    draw p rotated (180); draw p rotated (240); draw p rotated (300);
    p := ((0,.3u)--(0,0.2u)--(0.1u,0.2u)) rotatedaround ((0,0.2u),45);
    draw p; draw p rotated (60); draw p rotated (120);
    draw p rotated (180); draw p rotated (240);
    draw p rotated (300);
  );
  tmp_pic := image(
    for i = xpart llcorner q step 1.5u until xpart urcorner q:
      for j = ypart llcorner q step 1.5u until ypart urcorner q:
        z:=((i,j) randomized 1.3u);
	if xpart (P intersectiontimes ((bbox tmp_sn) shifted z)) < 0:
          draw tmp_sn shifted z;
	fi;
      endfor;
    endfor;
  );
  clip tmp_pic to P;
  drawoptions();
  draw tmp_pic;
enddef;

def a_blocks_SKBB (expr p) =
  T:=identity;
  pickup PenC;
  path q, qq; q = bbox p;
  picture tmp_pic;
  uu := max(u, (xpart urcorner q - xpart llcorner q)/100, (ypart urcorner q - ypart llcorner q)/100);
  tmp_pic := image(
    for i = xpart llcorner q step 2uu until xpart urcorner q:
      for j = ypart llcorner q step 2uu until ypart urcorner q:
        qq := punked (((-.5uu,-.5uu)--(.5uu,-.5uu)--(.5uu,.5uu)--(-.5uu,.5uu)--cycle)
	     randomized (uu/2))
             rotated uniformdeviate(360)
             shifted ((i,j) randomized 1.6uu);
	if xpart (p intersectiontimes qq) < 0:
	  thclean qq;
	  thdraw qq;
	fi;
      endfor;
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_blocks_SKBB_ (expr p,o,s_beg,s_end,d_beg,d_end) =
  T:=identity;
  orient = 90-o;
  pickup PenC;
  path q[], qq; q1 = bbox p;
  draw q1; draw p;
  q2 = llcorner q1 .. lrcorner q1 .. urcorner q1 .. ulcorner q1 .. cycle;
  draw q2;
  pair zz[];
  radius := .5*length(llcorner q1 - urcorner q1);
  zz1 := .5[llcorner q1,urcorner q1];
  zz2 := zz1 - dir(orient)*radius;
  zz3 = zz1 rotatedaround (zz2,90);
  draw zz1 withpen pencircle scaled 2mm;
  draw zz2 withpen pencircle scaled 2mm;
  draw zz3 withpen pencircle scaled 2mm;
  picture tmp_pic;
  tmp_pic := image(
    j := 0;
    forever:
      i := 0;
      forever:
        qq := punked (((-.5,-.5)--(.5,-.5)--(.5,.5)--(-.5,.5)--cycle)
             scaled (0.7(5u-(j/(2*radius))[u*s_beg,u*s_end]))
	     randomized (u/2))
             rotated uniformdeviate(360)
             shifted (((zz3 + (i,j)) rotatedaround (zz3,-o)) randomized 1.6u);
        draw ((zz3 + (i,j)) rotatedaround (zz3,-o)) withpen pencircle scaled 1mm withcolor red;
	if xpart (p intersectiontimes qq) < 0:
	  thclean qq;
	  thdraw qq;
	fi;
        i := i + (j/(2*radius))[u*d_beg,u*d_end];
        exitif i > 2*radius;
      endfor;
      j := j + (j/(2*radius))[u*d_beg,u*d_end];
      exitif j > 2*radius;
    endfor;
  );
%  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;


def a_pebbles_SKBB (expr p) =
  T:=identity;
  pickup PenC;
  path q, qq; q = bbox p;
  picture tmp_pic;
  tmp_pic := image(
    for i = xpart llcorner q step 1.5u until xpart urcorner q:
      for j = ypart llcorner q step 1.5u until ypart urcorner q:
        qq := (superellipse((.2u,0),(0,.1u),(-.2u,0),(0,.-.1u),.75))
%             randomized (u/25)
             rotated uniformdeviate(360)
             shifted ((i,j) randomized 0.8u);
	if xpart (p intersectiontimes qq) < 0:
	  thdraw qq;
	fi;
      endfor;
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_water_SKBB (expr Path) =
  T:=identity;
  thfill Path;
enddef;

let a_sump_SKBB = a_water_SKBB;

def a_u (expr p) =
    T:=identity;
    thfill p withcolor red;
enddef;




%%%%% ENDINPUT thArea %%%%%





%%%%% INPUT thText %%%%%


%% therion source code
%%
%% This file defines macros for labels
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: thText.mp,v $
%% $Revision: 1.6 $
%%
%% Copyright (C) 2000-2004 Martin Budaj
%%
%% --------------------------------------------------------------------
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

labeloffset:=0bp;

def l_label(expr txt,path) =
  picture pict,pic;
  pair pos;
  numeric dx[],dy[],ptime;
  string ss,ch;

  pic := thelabel(txt,(0,0));
  strl := xpart(lrcorner pic - llcorner pic);
  pathl := arclength (path);
  dx0 := xpart(llcorner pic);
%  dy0 := ypart(llcorner pic);

  if strl>pathl:
    txtzoom := pathl / strl;
    thwarning("text scaled down to fit the path");
  else:
    txtzoom := 1;
  fi;
  zoom := pathl / strl;

  for p within pic:
    if textual p:
      ss := textpart p;
      dx1 := xpart p;
      dy1 := ypart p;
      dx2 := dx1;

      if xxpart p / yypart p <> 1: message("Error: distorted text!") fi;
      txtscale := txtzoom * xxpart p;

      l := length(ss);
      ptime := 0;
      for i=0 upto (l - 1):
        ch := substring(i,i+1) of ss;
        pict := ch infont fontpart p scaled txtscale;
        charwidth := xpart (lrcorner pict - llcorner pict) / txtzoom;
        dy2 := ypart lrcorner pict / txtzoom;
        ptime := (dx2 - dx0 + 0.5*charwidth) * zoom;
        t := arctime ptime of (path);
        pos := point t of path +
          (dy1+dy2)*txtzoom*unitvector((direction t of path) rotated 90);
        begingroup
%          interim labeloffset:=0bp;
          lab:=thelabel.top(pict,pos);
          process_label(pos,angle direction t of path);
        endgroup;
        dx2 := dx2 + charwidth;
      endfor;

    else: message("Strange component of line label!");
    fi;
  endfor;
  % draw path;
enddef;


% Label processing modes
% 0 = generic label
% 1 = altitude with a dot and increased offset from the anchor point
% 2 = semi circle up
% 3 = semi circle down
% 4 = semi circle up + semi circle down
% 5 = circle
% 6 = boxed label
% 7 = generic label for station name with an increased offset from the anchor point
% 8 = filled label; not implemented in the standard symbol sets, but see samples/q-marks for a usage example
p_label_mode_label:=0;
p_label_mode_station:=7;
p_label_mode_altitude:=1;
p_label_mode_date:=0;
p_label_mode_passageheight:=5;
p_label_mode_passageheightpos:=2;
p_label_mode_passageheightneg:=3;
p_label_mode_passageheightposneg:=4;
p_label_mode_height:=7;
p_label_mode_debugscrap:=6;
p_label_mode_debugstation:=7;

vardef p_label@#(expr txt,pos,rot,mode) =
  if (mode=1) or (mode=7): interim labeloffset:=(u/8) fi;
  lab:=thelabel@#(txt, pos);
  if mode>1: pickup PenD fi;
  if mode=1:
    pickup pencircle scaled (u/6);
    drawdot(pos);
    process_label(pos,0);
  elseif mode=2: process_uplabel;
  elseif mode=3: process_downlabel;
  elseif mode=4: process_updownlabel;
  elseif mode=5: process_circledlabel;
  elseif mode=6: process_boxedlabel;
  elseif mode=7: process_label(pos,rot);  % station name
  elseif mode=8: process_filledlabel(pos, rot);
  else: process_label(pos,rot); fi;
enddef;


% at beginfig: save smartll[], smartur[]; pair smartll[], smartur[]; smart_count=0;
numeric smart_count, smart_D;
boolean smart_quit, smart_inner_quit;

def p_smartlabel (expr txt, pos) =
  begingroup;
  interim bboxmargin:=0.2pt;
  lab:=thelabel.rt(txt,pos+(0.4u,0));
  q:=bbox lab;
  smart_D := 0;
  forever:
    smart_quit := true;
    smart_inner_quit := false;
    for i=1 upto smart_count:
      if smart_overlap(((point 0 of q) shifted (0,smart_D)),
                       ((point 2 of q) shifted (0,smart_D)),
                       smartll[i], smartur[i]) = 1:
        smart_quit := false;
        smart_D := smart_D - 3pt;
        smart_inner_quit := true;
      fi;
      exitif smart_inner_quit;
    endfor;
    exitif smart_quit;
  endfor;
  smart_U := 0;
  forever:
    smart_quit := true;
    smart_inner_quit := false;
    for i=1 upto smart_count:
      if smart_overlap(((point 0 of q) shifted (0,smart_U)),
                       ((point 2 of q) shifted (0,smart_U)),
                       smartll[i], smartur[i]) = 1:
        smart_quit := false;
        smart_U := smart_U + 3pt;
        smart_inner_quit := true;
      fi;
      exitif smart_inner_quit;
    endfor;
    exitif smart_quit;
  endfor;
  if (smart_U < -smart_D): smart_D := smart_U; fi;
  draw lab shifted (0,smart_D);
  if (abs(smart_D)>3pt):
    pickup PenB;
    draw pos{left}..{right}(pos shifted (.4u, smart_D)) dashed withdots scaled 0.2;
    pickup PenA;
    drawdot pos;
  fi;
  smart_count := smart_count + 1;
  smartll[smart_count] := point 0 of (q shifted (0,smart_D));
  smartur[smart_count] := point 2 of (q shifted (0,smart_D));
  endgroup;
enddef;

def smart_overlap (expr llA, urA, llB, urB) =
  if ((xpart llA < xpart urB) and (xpart urA > xpart llB)) and
     ((ypart llA < ypart urB) and (ypart urA > ypart llB)):
    1
  else:
    0
  fi
enddef;




def p_wallaltitude (expr pprev,pos,pnext,txt) =
  rot:=angle(unitvector(pnext-pos)+unitvector(pos-pprev)) - 90;
  pickup PenD;
  pair zz;
%  zz:=(pos + 3*unitvector(dir rot));
  zz:=(pos + (u/4)*unitvector(dir rot));
  draw (pos)--zz;
  begingroup
%    interim labeloffset:=2pt;
    interim labeloffset:=(u/12);
    if horiz_labels:
      rot:=rot mod 360;
      if rot<=22.5: lab:=thelabel.rt(txt, zz);
      elseif rot<=67.5: lab:=thelabel.urt(txt, zz);
      elseif rot<=112.5: lab:=thelabel.top(txt, zz);
      elseif rot<=157.5: lab:=thelabel.ulft(txt, zz);
      elseif rot<=202.5: lab:=thelabel.lft(txt, zz);
      elseif rot<=247.5: lab:=thelabel.llft(txt, zz);
      elseif rot<=292.5: lab:=thelabel.bot(txt, zz);
      elseif rot<=337.5: lab:=thelabel.lrt(txt, zz);
      else: lab:=thelabel.rt(txt, zz);
      fi;
    else:
      if (abs rot>90) and (abs rot <=270):
        rot:=rot-180;
        lab:=thelabel.lft(txt, pos);
      else:
        lab:=thelabel.rt(txt, pos);
      fi;
    fi;
    process_label(pos, if horiz_labels: 0 else: rot fi);
  endgroup;
enddef;




%%%%% ENDINPUT thText %%%%%





%%%%% INPUT thSpecial %%%%%


%% therion source code
%%
%% This file defines macros for special symbols
%%
%% $Date: $
%% $RCSfile: $
%% $Revision: $
%%
%% Copyright (C) 2004 Martin Budaj
%%
%% --------------------------------------------------------------------
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

def s_northarrow_SKBB_old (expr rot) =
  T:=identity;
  picture tmp_pic;
  tmp_pic = image (
    begingroup
      interim defaultscale:=3;
      label(if (lang="sk") or (lang="cz"): "S" else: "N" fi, origin);
    endgroup;
    drawarrow (0,-1cm)--(0,1cm);
  );
  draw tmp_pic rotatedaround(origin, -rot);
enddef;

def s_northarrow_SKBB (expr rot) =
  T:=identity scaled 0.7 rotated -rot;
  thdraw (-.5cm,-1cm)--(0,1.5cm)--(.5cm,-1cm)--(0,-.5cm)--cycle;
  thfill (-.5cm,-1cm)--(0,1.5cm)--(0,-.5cm)--cycle;
enddef;

def s_scalebar_SKBB (expr l, units, txt) =
  begingroup
    interim warningcheck:=0;
    tmpl:=l / Scale * cm * units / 2;
  endgroup;
  pickup PenC;
  draw (-tmpl,0)--(tmpl,0);
  draw (-tmpl,0)--(-tmpl,2bp);
  draw (tmpl,0)--(tmpl,2bp);
  begingroup
    interim labeloffset:=2bp;
    label.top(thTEX(decimal (l) & "\thinspace" & txt),origin);
  endgroup
enddef;

def s_scalebar_SM (expr l, units, txt) =
  begingroup
    interim warningcheck:=0;
    tmpl:=l / Scale * cm * units / 2;
  endgroup;
  pickup PenC;
  draw (-tmpl,0)--(tmpl,0);
  draw (-tmpl,0)--(-tmpl,2bp);
  draw (tmpl,0)--(tmpl,2bp);
  draw (0,0)--(0,2bp);
  begingroup
    interim labeloffset:=3.5bp;
    label.top(thTEX(decimal (0)),(-tmpl,0));
    label.top(thTEX(decimal (l/2)),origin);
    label.top(thTEX(decimal (l) & "\thinspace" & txt),(tmpl,0));
  endgroup
enddef;


def s_hgrid_SM (expr xpos, ypos, xsize, ysize) =
  pickup PenD;
  draw (
    if xpos < 0: 0 else: -5mm fi, 0
  ) -- (
    if xpos > 0: 0 else: 5mm fi, 0
  );
  draw (
    0, if ypos < 0: 0 else: -5mm fi
  ) -- (
    0, if ypos > 0: 0 else: 5mm fi
  );
enddef;


def s_vgrid_SM (expr xpos, ypos, xsize, ysize) =
  pickup PenD;
  draw (
    if xpos < 0: 0 else: -xsize/2 fi, 0
  ) -- (
    if xpos > 0: 0 else: xsize/2 fi, 0
  ) dashed evenly;
enddef;




%%%%% ENDINPUT thSpecial %%%%%





%%%%% INPUT uAUT %%%%%


% Austrian Symbol Set, author Georg Pacher
% enhanced 2017 by Benedikt Hallinger

% color (for Austrian symbol-set)

color col_water_bg;
col_water_bg :=(226/255,244/255,253/255);

%%%%%%%%%%%%%%%%%%%%%%%


%% areas

% returns true if pair point lies within path q.
% outside_point is any pair outside of path q (needed for reference).
vardef pointinside(expr pt,q,outside_point)=
  T:=identity;
  path test;
  test:= outside_point--pt;
  %thdraw test;
  boolean isinside;
  isinside:=false;
  numintersections:=recgetnumintersections(test,q,0);
  if (numintersections <0):
    isinside:=true;
  elseif odd(numintersections):
     isinside:=true;
  else:
     isinside:=false;
  fi;
  isinside
enddef;

% get number of intersection between paths p (length 1!) and q
% recnum is needed for limitation of recursions.
% If the number of allowed recursions is reached, a negative number of intersections is returned
vardef recgetnumintersections(expr p,q,recnum)=

  pair inter;
  save preinter;
  save postinter;
  save numintersections;
  path preinter, postinter;
  inter:=p intersectiontimes q;
  %show recnum;
  if recnum >25:
    numintersections:=-100;
  else:
    if xpart(inter)>0 :
     %show (xpart inter);
    % split p into two paths and call yourself again

    preinter:=subpath (0,xpart(inter)-2eps) of p;

    postinter:=subpath (xpart(inter)+2eps,1) of p;

    numintersections:= recgetnumintersections(preinter,q,recnum+1)
                     + recgetnumintersections(postinter,q,recnum+1)
                     + 1;
    else:
      numintersections:=0;
    fi;
  fi;
  numintersections

enddef;

beginpattern(pattern_water_AUT);
    draw origin--10up withpen pensquare scaled (0.02u);
    patternxstep(.18u);
    patterntransform(identity rotated 90);
endpattern;

beginpattern(pattern_sump_AUT);
    draw origin--(0,.25u) withpen pensquare scaled (0.02u);
    draw origin--(.25u,0) withpen pensquare scaled (0.02u);
endpattern;

beginpattern(pattern_sand_AUT);
    pickup PenC;
    p:= origin -- (0.01u,0.01u);
    for i=0.0u step 0.2u until 2.4u:
        for j=0.0u step 0.2u until 2.4u:
          draw p rotated uniformdeviate(360)
           shifted ((i,j) randomized 0.09u);
        endfor;
    endfor;
    if BaseScale<=2.5:
      my_step:=2.4u;
    else:
      my_step:=2.6u;
    fi;
    patternstep(my_step,my_step);
endpattern;

beginpattern(pattern_pebbles_AUT);
    pickup PenC;
    path qq;
    for i=0.0u step 0.3u until 5.1u:
        for j=0.0u step 0.3u until 5.1u:
          qq := (superellipse((.1u,0),(0,.05u),(-.1u,0),(0,.-.05u),.75))
             randomized (u/45)
             scaled (uniformdeviate(0.4)+.55)
             rotated uniformdeviate(360)
             shifted ((i,j) randomized 0.15u);
           draw qq;
        endfor;
    endfor;
    patternstep(5.1u,5.1u);
endpattern;

beginpattern(pattern_ice_AUT);
    pickup PenC;
    p:=(-.15u,.0u) -- (0.15u,.0u);
    draw p;
    draw p shifted (0.25u,.0u) rotated (90);
    draw p shifted (0.45u,0.25u);
    draw p shifted (0.0u,0.45u) rotated (90);
    patternxstep(.9u);
    patternystep(0.5u);
endpattern;

beginpattern(pattern_flowstone_AUT);
    pickup PenC;
    draw (0.0u, 0.01u)--(0.33u, 0.01u);
    draw (0.33u, 0.33u)--(0.66u, 0.33u);
    patternbbox(0u,0u, 0.66u, 0.66u); % definiert Rechteckgroesse des Symbols
endpattern;

def a_water_AUT (expr Path) =
  T:=identity;
  thclean Path;
  pickup PenC;
  thfill Path withcolor col_water_bg;
  thfill Path withpattern pattern_water_AUT;
  thdraw Path;
enddef;

def a_sump_AUT (expr Path) =
  T:=identity;
  thclean Path;
  pickup PenC;
  thfill Path withcolor col_water_bg;
  thfill Path withpattern pattern_sump_AUT;
  thdraw Path;
enddef;

def a_sand_AUT (expr Path) =
  T:=identity;
%  thclean Path;
  thfill Path withpattern pattern_sand_AUT ;
enddef;

def a_clay_AUT (expr Path) =
  T:=identity;
%  thclean Path;
  thfill Path withpattern pattern_sand_AUT;
enddef;


def a_pebbles_AUT (expr p) =
  T:=identity;
  thfill p withpattern pattern_pebbles_AUT;
enddef;



def a_debris_AUT (expr p) =
  T:=identity;

  symbol_distance:=1.0;
  scale_factor:= 0.3;
  pickup PenC;
  path q, qq; q = bbox p;
  pair outside;
  outside:= ulcorner q + up;
  picture tmp_pic;
  uu := max(u, (xpart urcorner q - xpart llcorner q)/100, (ypart urcorner q - ypart     llcorner q)/100);
  tmp_pic := image(
     for i = xpart llcorner q step symbol_distance*uu until xpart urcorner q:
        for j = ypart llcorner q step symbol_distance*uu until ypart urcorner q:
           qq := punked (((-.5uu,-.5uu)--(.5uu,-.5uu)--(1.05uu,0.01uu)--(.5uu,.5uu)--(-.5uu,.5uu)--cycle)
           randomized (uu/2))
           scaled (uniformdeviate(0.4)+scale_factor )
           rotated uniformdeviate(360)
           shifted ((i,j) randomized 0.5uu);
           if xpart (p intersectiontimes qq) < 0:
             if pointinside((i,j),p,outside):
               thclean qq;
               thdraw qq;
             fi;
           else:
             qq:= qq scaled (uniformdeviate(.2)+.5 )
             if xpart (p intersectiontimes qq) < 0:
               if pointinside((i,j),p,outside):
                 thclean qq;
                 thdraw qq;
               fi;
             fi;
           fi;
        endfor;
     endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_ice_AUT (expr p) =
  T:=identity;
  thclean p;
  thfill p withpattern pattern_ice_AUT;
  pickup PenC;
  thdraw p;
enddef;

def a_snow_AUT (expr P) =
  T:=identity;
  pickup PenC;
  path q; q = bbox P;
  picture tmp_pic, tmp_sn;
  pair z;
  tmp_sn := image(
    pickup PenC;
    p := origin--(0,.2*u);
    draw p; draw p rotated (60); draw p rotated (120);
    draw p rotated (180); draw p rotated (240); draw p rotated (300);
    p := ((0,.3u)--(0,0.2u)--(0.1u,0.2u)) rotatedaround ((0,0.2u),45);
    draw p; draw p rotated (60); draw p rotated (120);
    draw p rotated (180); draw p rotated (240);
    draw p rotated (300);
  );
  tmp_pic := image(
    for i = xpart llcorner q step 1.0u until xpart urcorner q:
      for j = ypart llcorner q step 1.0u until ypart urcorner q:
        z:=((i,j) randomized 0.5u);
	if xpart (P intersectiontimes ((bbox tmp_sn) shifted z)) < 0:
          draw tmp_sn shifted z;
	fi;
      endfor;
    endfor;
  );
  clip tmp_pic to P;
  draw tmp_pic;
  thdraw P;
enddef;

def a_blocks_AUT (expr p) =
   T:=identity;
  symbol_distance:=1.6;
  scale_factor:= 0.8;
  pickup PenC;
  path q, qq; q = bbox p;
  pair outside;
  outside:= ulcorner q + up;
  picture tmp_pic;
  uu := max(u, (xpart urcorner q - xpart llcorner q)/100, (ypart urcorner q - ypart     llcorner q)/100);
  tmp_pic := image(
     for i = xpart llcorner q step symbol_distance*uu until xpart urcorner q:
        for j = ypart llcorner q step symbol_distance*uu until ypart urcorner q:
           qq := punked (((-.5uu,-.5uu)--(.5uu,-.5uu)--(1.05uu,0.01uu)--(.5uu,.5uu)--(-.5uu,.5uu)--cycle)
           randomized (uu/2))
           scaled (uniformdeviate(0.7)+scale_factor )
           rotated uniformdeviate(360)
           shifted ((i,j) randomized 0.75uu);
           if xpart (p intersectiontimes qq) < 0:
             if pointinside((i,j),p,outside):
               thclean qq;
               thdraw qq;
             fi;
           else:
             qq:= qq scaled (uniformdeviate(.2)+.5 );
             if xpart (p intersectiontimes qq) < 0:
               if pointinside((i,j),p,outside):
                 thclean qq;
                 thdraw qq;
               fi;
             fi;
           fi;
        endfor;
     endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;


def a_flowstone_AUT (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_flowstone_AUT ;
enddef;



%% lines

def l_wall_pit_AUT (expr P) =
    T:=identity;
    % draw outer path
    pickup PenA;
    thdraw P;

    laenge:= arclength P;

    pair inner[],innerdir[], inter;
    pair test;

    samplingdistance:=max(0.15u,laenge/1500);

    path testcircle;
    % testcircle, used to test, whether the path makes a 'v'-like bend,
    % where normal sampling and offsetting gives poor results for the parallel line
    % size of testcircle= size PenA/2 + 2* (distance between outer and inner line)
    % + PenC (inner line)
    testcircle := halfcircle scaled (.5*u/10+2*.125u+.5*u/10) shifted (0,.5*u/10);
    cur:=samplingdistance/2;
    count:=0;
    forever:
      t:= arctime cur of P;
      inter:=P intersectiontimes (testcircle rotated (angle thdir(P,t)) shifted (point t of P));

      %thdraw testcircle rotated (angle thdir(P,t)) shifted (point t of P) withpen (pencircle scaled 0.01u) ;
      if (xpart inter) >=0:
        % we are at a 'sharp bend', so set next point to intersectionpoint
        cur:=cur+samplingdistance;
        t := max( xpart inter, arctime cur of P);
        %thdraw point t of P withcolor 0.7*green;
        forever:
          t:= arctime cur of P;
          inter:=P intersectiontimes (testcircle rotated (angle thdir(P,t)) shifted (point t of P));
          exitif (xpart inter <0);
          cur := cur + samplingdistance;
          exitif (cur >=laenge);
        endfor;
        if (cur <laenge):
          inner[count]:=(point t of P + .125u*unitvector(thdir(P,t) rotated 90) );
          innerdir[count]:=unitvector(thdir(P,t));
          count := count+1;
        fi;
      else:
        inner[count]:= (point t of P + .125u*unitvector(thdir(P,t) rotated 90) );
        innerdir[count]:=unitvector(thdir(P,t));
        %thdraw inner[count] withpen PenD withcolor 0.5*red;
        count:=count +1;
        cur:= cur+ samplingdistance;
      fi;
      exitif (cur >=laenge);
    endfor;
    if count>2:
      % draw inner path
      pickup PenC;
      path innerpath;
      innerpath =
      for i=0 upto count-2:
        inner[i]{(innerdir[i])} ..
      endfor
      if cycle P: cycle;
      else:  inner[count-1];
      fi;
      thdraw innerpath;

    % draw the triangles

    path draw_triangle;
    pair l_triangle;

    laenge:= arclength innerpath;
    symsize:= adjust_step(laenge,0.5u);
    triangle_width:=symsize/2;
    cur:=(symsize/2);
    t := arctime (cur) of innerpath;
    t1:= arctime (cur-triangle_width/2) of innerpath;
    t2:= arctime (cur+triangle_width/2) of innerpath;
    l_triangle := (point t of innerpath);
    if ATTR__height >= 10: thfill else: thdraw fi (subpath (t1,t2) of innerpath) --
           ((point t of innerpath) + symsize/2 * unitvector(thdir(innerpath,t) rotated 90))
           --  cycle;

    for cur=(symsize/2) step symsize until laenge:
      t := arctime (cur) of innerpath;
      test := (point t of innerpath);
      my_dist := length(test-l_triangle);
      if (abs(my_dist-symsize) < 0.05u) or (my_dist>symsize):
         t1:= arctime (cur-triangle_width/2) of innerpath;
         t2:= arctime (cur+triangle_width/2) of innerpath;
	 draw_triangle:=(subpath (t1,t2) of innerpath) --
                        ((point t of innerpath) + symsize/2 * unitvector(thdir(innerpath,t) rotated 90))
                         --  cycle;
	 if xpart (draw_triangle intersectiontimes P) < 0:
	    if ATTR__height >= 10:
	      thfill draw_triangle;
	    else:
	      thclean draw_triangle;
	      thdraw draw_triangle;
	    fi;
	    l_triangle:= test;
	 fi;
      fi;
    endfor;

    fi;
enddef;


def l_wall_sand_AUT (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.1u);
  pickup PenC;
  forever:
    t := arctime cas of P;
    thdraw (((0.01u,0.01u)--origin) rotated uniformdeviate(360) shifted ((point t of P) + (uniformdeviate 1) * .4u
            * unitvector(thdir(P,t) rotated -90)));
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
  endfor;
  pickup PenC;
  thdraw P;

enddef;

def l_wall_pebbles_AUT (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .18u);
  pickup PenC;
  q:=superellipse((.1u,0),(0,.05u),(-.1u,0),(0,.-.05u),.75);
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw q randomized (u/45) rotated (angle(thdir(P,t)) + (normaldeviate*40)) shifted point t of P;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;


let l_wall_clay_AUT = l_wall_sand_AUT;


def l_wall_debris_AUT (expr P) =
  T:=identity;
  pickup PenC;
  laenge := arclength P;
  path block;
  path old_block;

  cur := 0;
  t:= arctime cur of P;
  % draw first block
  old_block := (((-.0u,-.0u)--(.25u,-.15u)--(.45u,0.01u)--(.2u,.25u)--(.05u,.15u)--cycle));
  block_width := (xpart urcorner old_block - xpart ulcorner old_block);
  old_block:=old_block rotated angle(thdir(P,0)) shifted point t of P;
  thclean old_block;
  thdraw old_block;

  cur := cur + 0.9*block_width;
  t:= arctime cur of P;
	% proceed with path
    forever:
	  % generate random block
        block := punked (((-.25u,-.25u)--(0.25.u,-.25u)--(0.50u,0.01u)--(0.25u,.25u)--(-.25u,.25u)--cycle)
          randomized (u/4))
          scaled (uniformdeviate(0.3)+.4)
          rotated uniformdeviate(360);
	  % check width of block
        block_width := (xpart urcorner block - xpart ulcorner block);
        exitif cur > (laenge- 2.5*block_width/2);
        % find next position where the block fits in without intersecting the previous one
	  forever:
	    exitif xpart ( (block rotated angle(-direction t of P) shifted point t of P) intersectiontimes old_block) < 0;
            cur:=cur+0.01u;
            t:= arctime cur of P;
            exitif cur > (laenge- 2.5*block_width/2);
          endfor;
        exitif cur > (laenge- 2.5*block_width/2);

        old_block:= block rotated angle(-direction t of P) shifted point t of P;
        thclean old_block;
        thdraw old_block;
        cur := cur + block_width/2;
        t:= arctime cur of P;
    endfor;
	t:= arctime laenge-eps of P;

	% generate last block
      block := (((-.0u,-.0u)--(.25u,-.15u)--(.45u,0.01u)--(.2u,.25u)--(.1u,.15u)--cycle));
     block_width := (xpart urcorner block - xpart ulcorner block);

	% scale last block to fit in the remaining gap
     scale_factor:=1.5*(laenge-cur)/block_width;
     forever:
           exitif scale_factor < 0;  % bruces stab at preventing endless loop at large scales
           exitif xpart ( (block rotated angle(-direction t of P) scaled scale_factor shifted (point t of P)) intersectiontimes old_block) < 0;
           scale_factor:=scale_factor-0.01;
     endfor;
     if scale_factor > 0:
       thclean block rotated angle(-direction t of P) scaled scale_factor shifted (point t of P);
       thdraw block rotated angle(-direction t of P) scaled scale_factor shifted (point t of P);
     fi;
enddef;


def l_wall_blocks_AUT (expr P) =

  T:=identity;
  pickup PenC;
  laenge := arclength P;

  path block;
  path old_block;

  cur := 0;
  t:= arctime cur of P;

  % draw first block
  old_block := ( (.7u,-.35u)--(.85u,0.01u)--(.4u,.5u)--(.1u,.3u)--(-.0u,-.0u) );
  block_width := (xpart urcorner old_block - xpart ulcorner old_block);
  old_block:=old_block rotated angle( thdir(P,0) ) shifted point t of P;
  thclean (old_block--cycle);
  thdraw old_block;


  cur := cur + block_width/2;
  t:= arctime cur of P;
  forever:
    % generate random block
    block := punked ( ( (.8u,-.35u)--(.85u,0.01u)--(.6u,.4u)--(.1u,.1u)--(-.0u,-.3u) )
          randomized (0.3u) )
           scaled (uniformdeviate(0.3)+.65)
          rotated (uniformdeviate(45)-15);
    % check width of block
    block_width := (xpart urcorner block - xpart ulcorner block);

    exitif cur > (laenge- 3.5*block_width/2);
    % find next position where the block fits in without intersecting the previous one
    forever:
      exitif xpart ( ((block--cycle) rotated angle(direction t of P) shifted point t of P) intersectiontimes old_block) < 0;
      cur:=cur+0.01u;
      t:= arctime cur of P;
      exitif cur > (laenge- 3.5*block_width/2);
    endfor;
    exitif cur > (laenge- 3.5*block_width/2);

    old_block:= block rotated angle(direction t of P) shifted point t of P;
    thclean (old_block--cycle);
    thdraw old_block;


    cur := cur + block_width/2;
    t:= arctime cur of P;
  endfor;

    % generate last block
    t:= arctime laenge-eps of P;
    block := (( (-.15u,-.35u)--(.0u,.0u)--(-.45u,.5u)--(-.75u,.3u)--(-.85u,-.0u)) );
    block_width := (xpart urcorner block - xpart ulcorner block);
    % scale last block to fit in the remaining gap
    scale_factor:=(laenge-cur)/block_width;
    forever:
	  exitif scale_factor < 0;
      exitif xpart ( ( (block) rotated angle (direction t of P) scaled scale_factor shifted (point t of P) ) intersectiontimes old_block) < 0;
      scale_factor:=scale_factor-0.001;
    endfor;
    if scale_factor > 0:
      thclean (block--cycle) rotated angle (direction t of P) scaled scale_factor shifted (point t of P);
      thdraw (block) rotated angle (direction t of P) scaled scale_factor shifted (point t of P);
    fi;
enddef;



def l_wall_ice_AUT (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .6u);
  pickup PenC;
  p := (-.15u,0)--(.15u,0);
  q := p rotated 90 shifted (.25u,.0u);
  picture symbol,test_symbol;
  symbol:= image (
             thdraw p;
             thdraw q;
             );
  path bound,old_bound,test_bound;
  begingroup;
    interim bboxmargin:=0;
    bound := bbox (symbol);
  endgroup;
  t := arctime (cas + mojkrok/2) of P;
  thdraw symbol rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
  old_bound:=bound rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));

  forever:
    t := arctime (cas + mojkrok/2) of P;
    test_bound:= bound rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
    if xpart ((old_bound) intersectiontimes (test_bound))<0:
      if xpart (P intersectiontimes (test_bound))<0:
        thdraw symbol rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
        old_bound:=bound rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
      fi;
    fi;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
  thdraw P;
enddef;


def l_wall_underlying_AUT (expr P) =
  T:=identity;
  pickup PenA;
  laenge:= arclength P;
  t1 := arctime (0.5u) of P;
  t2 := arctime (laenge-.5u) of P;
  thdraw (subpath (t1,t2) of P) dashed evenly scaled optical_zoom;
enddef;


def l_wall_overlying_AUT (expr P) =
  T:=identity;
  laenge:= arclength P;
  t1 := arctime (0.25u) of P;
  t2 := arctime (laenge-.25u) of P;
  t3 :=arctime (laenge) of P;
  pickup pensquare scaled (3.5*u/10);
  thdraw (subpath (t1,t2) of P) withcolor background;
    pickup PenA;
  thdraw subpath(0,t1) of P;
  thdraw subpath(t2,t3) of P;
  thdraw (subpath (t1,t2) of P) dashed dashpattern(on 2bp off 2bp on .5bp off 2bp on 2bp) scaled optical_zoom;
enddef;

def l_wall_moonmilk_AUT (expr P) =
  T:=identity;
  laenge:= arclength P;
  symsize:=adjust_step(laenge,0.8u);
  circle_width:=symsize/2;
  cur:=(symsize-circle_width)/2;
  pickup PenC;
  forever:
    t1 := arctime (cur) of P;
    t2 := arctime (cur + circle_width) of P;
    thdraw (point t1 of P){dir (angle(thdir(P,t1)) + 90)} ..
           {dir (angle(thdir(P,t2)) - 90)}(point t2 of P);
    cur := cur + symsize;
    exitif cur > laenge + (symsize / 3); % for rounding errors
  endfor;
  pickup PenA;
  thdraw P;
enddef;

def l_wall_flowstone_AUT (expr P) =
  T:=identity;
  laenge:= arclength P;
  symsize:=adjust_step(laenge,0.8u);
  circle_width:=symsize/2;
  cur:=(symsize-circle_width)/2;
  pickup PenC;
  forever:
    t1 := arctime (cur) of P;
    t2 := arctime (cur + circle_width) of P;
    thdraw (point t1 of P){dir (angle(thdir(P,t1)) + 90)} ..
           {dir (angle(thdir(P,t2)) - 90)}(point t2 of P);
    thfill (point t1 of P){dir (angle(thdir(P,t1)) + 90)} ..
           {dir (angle(thdir(P,t2)) - 90)}(point t2 of P) --
           (point t1 of P)--cycle;
    cur := cur + symsize;
    exitif cur > laenge + (symsize / 3); % for rounding errors
  endfor;
  pickup PenA;
  thdraw P;
enddef;

def l_pit_AUT (expr P) =
  T:=identity;
  laenge:= arclength P;
  symsize:=adjust_step(laenge,0.5u);
  triangle_width:=symsize/2;
  cur:=(symsize-triangle_width)/2;
  pickup PenC;
  forever:
    t1 := arctime (cur) of P;
    t  := arctime (cur + triangle_width/2) of P;
    t2 := arctime (cur + triangle_width) of P;
    if ATTR__height >= 10:
      thfill (subpath (t1,t2) of P) --
        ((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) --
        cycle;
    else:
      thclean (subpath (t1,t2) of P) --
        ((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) --
        cycle;
      thdraw (point t2 of P) --((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) --
        (point t1 of P);
    fi;
    cur := cur + symsize;
    exitif cur > laenge - (1*symsize/3); % for rounding errors
    t1:=arctime (cur) of P;
  endfor;
  thdraw P;
enddef;


let l_overhang_AUT = l_pit_AUT;

let l_floorstep_AUT = l_floorstep_UIS;

let l_contour_AUT =l_contour_SKBB;

let l_ceilingstep_AUT = l_ceilingstep_UIS;

let l_ceilingmeander_AUT = l_ceilingmeander_UIS;

def l_flowstone_AUT (expr P) =
  T:=identity;
  pickup PenC;
  thdraw P dashed evenly scaled optical_zoom;
enddef;

def l_survey_cave_AUT (expr P) =
  T:=identity;
  pair zz[];
  pickup PenD;
  thdraw P;
enddef;

%% points

def p_stalactite_AUT(expr pos,theta,sc,al) =
    pickup PenC;
    if ATTR__elevation:
      U:=(.15u, .4u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
      thdraw (0,.15u) -- (.15u,.4u);
    else:
      U:=(.175u, .175u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thclean fullcircle scaled 0.35u;
      thdraw fullcircle scaled 0.35u;
    fi;
enddef;

let p_icestalactite_AUT = p_stalactite_AUT;

def p_stalagmite_AUT(expr pos,theta,sc,al) =
    pickup PenC;
    if ATTR__elevation:
      U:=(.15u,.4u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
      thdraw (0,-.15u) -- (.15u,-.4u);
    else:
      U:=(.15u,.15u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thfill fullcircle scaled 0.3u;
    fi;
enddef;

let p_icestalagmite_AUT = p_stalagmite_AUT;

def p_pillar_AUT(expr pos,theta,sc,al) =
    pickup PenC;
    if ATTR__elevation:
      U:=(.15u,.4u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thdraw (0,.15u)--(0,-.15u);
      thdraw (-.15u,-.4u)--(0,-.15u)--(.15u,-.4u);
      thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
    else:
      U:=(.225u,.225u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thclean fullcircle scaled 0.45u;
      thdraw fullcircle scaled 0.45u;
      thfill fullcircle scaled 0.3u;
    fi;
enddef;

let p_icepillar_AUT = p_pillar_AUT;

def p_crystal_AUT (expr pos,theta,sc,al)=
    U:=(.35u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;

    pickup PenC;
    p := ((-.35*u,0)--(.35*u,0));
    thdraw p;
    thdraw p rotated (45);
    thdraw p rotated (90);
    thdraw p rotated (135);

    thdrawoptions();

enddef;

def p_spring_AUT (expr pos,theta,sc,al)=
  U:=(.3u,.2u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.3u,.1u)..(0,-.1u)..(.3u,.1u);
enddef;


def p_sink_AUT (expr pos,theta,sc,al)=
  U:=(.3u,.2u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.3u,-.1u)..(0,.1u)..(.3u,-.1u);
enddef;

def p_breakdownchoke_AUT (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity rotated -theta aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thclean (-.4u,-.4u)--(.4u,-.4u)--(.4u,.4u)--(-.4u,.4u)--cycle;
    thdraw (-.4u,-.4u)--(.4u,-.4u)--(.4u,.4u)--(-.4u,.4u)--cycle;
    thdraw (-.21u,.305u)--(.0u,-.305u)--(.21u,.305u);
enddef;

def p_sand_AUT (expr pos,theta,sc,al)=
    U:=(.2u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:= origin -- (0.01u,0.01u);
    for i=-0.1u step 0.2u until .15u:
        for j=-0.1u step 0.2u until .15u:
          thdraw p rotated uniformdeviate(360)
           shifted ((i,j) randomized 0.09u);
        endfor;
    endfor;
    thdrawoptions();
enddef;

let p_clay_AUT  = p_sand_AUT;

def p_pebbles_AUT (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    path qq;
    for i=-0.15u step 0.3u until .2u:
        for j=-0.15u step 0.3u until .2u:
          qq := (superellipse((.1u,0),(0,.05u),(-.1u,0),(0,.-.05u),.75))
             randomized (u/45)
             scaled (uniformdeviate(0.4)+.55)
             rotated uniformdeviate(360)
             shifted ((i,j) randomized 0.15u);
           thdraw qq;
        endfor;
    endfor;
enddef;

def p_debris_AUT (expr pos,theta,sc,al)=
    U:=(.5u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    path block,q;
    block :=  ((-.15u,-.15u)--(.15u,-.15u)--(.3u,0.01u)--(.15u,.15u)--(-.15u,.15u)--cycle) ;

    q:= (punked (block randomized (0.15u))) rotated uniformdeviate(360) scaled (uniformdeviate(0.3)+0.3) shifted (0.0u,0.15u);
    thclean q; thdraw q;

    q:= (punked (block randomized (0.15u))) rotated uniformdeviate(360) scaled (uniformdeviate(0.5)+0.7) shifted (-0.15u,-0.15u);
    thclean q; thdraw q;

    q:=  (punked (block randomized (0.15u))) rotated uniformdeviate(360) shifted (0.15u,-0.15u);
    thclean q; thdraw q;

enddef;

def p_blocks_AUT (expr pos,theta,sc,al)=
    U:=(u,u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;

    path block,q;
    block :=  ((-.25u,-.25u)--(.25u,-.25u)--(.5u,0.01u)--(.25u,.25u)--(-.25u,.25u)--cycle) ;

    q:= (punked (block randomized (0.3u))) rotated uniformdeviate(360) scaled (uniformdeviate(0.3)+0.3) shifted (0.0u,0.25u);
    thclean q; thdraw q;

    q:= (punked (block randomized (0.3u))) rotated uniformdeviate(360) scaled (uniformdeviate(0.5)+0.7) shifted (-0.25u,-0.25u);
    thclean q; thdraw q;

    q:=  (punked (block randomized (0.3u))) rotated uniformdeviate(360) shifted (0.25u,-0.25u);
    thclean q; thdraw q;

enddef;

def p_water_AUT (expr pos,theta,sc,al)=
    U:=(.425u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenD;
    p:=fullcircle xscaled (.85u) yscaled (.6u);
    thfill p withcolor col_water_bg;
    thfill p withpattern pattern_water_AUT;
    thdraw p;
enddef;

def p_ice_AUT (expr pos,theta,sc,al)=
    U:=(.6u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(-.15u,.0u) -- (0.15u,.0u);
    thdraw p rotated 90;
    thdraw p shifted (0.45u,.0u);
    thdraw p shifted (-0.45u,.0u);

    thdraw p rotated 90 shifted (-0.45u,0.25u);
    thdraw p shifted (0u,0.25u);
    thdraw p rotated 90 shifted (0.45u,.25u);
enddef;

def p_entrance_AUT (expr pos,theta,sc,al)=
    U:=(.3u,.75u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    path slice;
    for i= -0.5 step 0.01 until 0.5:
      slice:= (-.3u*(0.5-i),1.5*i*u)--(0,.75u)--(.3u*(0.5-i),1.5i*u)--cycle;
      thfill slice withcolor (min(0.95,0.5-1.75i),min(0.95,.5-1.75i),min(0.95,.5-1.75i));
    endfor;
    thdraw ((-.3u,-0.75u)--(0,.75u)--(.3u,-0.75u)--cycle);
enddef;

def p_gradient_AUT (expr pos,theta,sc,al)=
    U:=(.15u,u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-0.5u)--(0,0.5u);
    p:=(-.15u,.3u)--(0,0.7u)--(.15u,.3u)--cycle;
    thfill p;
    thdraw p;
enddef;

def p_airdraught_AUT (expr pos,theta,sc,al)=
  U:=(.2u,u);
  T:=identity aligned al rotated theta scaled 1 shifted pos;
  pickup PenC;
  thdraw (0,.5u)--(0,-0.8u);
	p:=(-.2u,.2u)--(0,.55u)--(.2u,.2u)--cycle;
	thfill p;
	for i:=1 upto round(3+2*mlog(sc)/mlog 2):
	  thdraw (0,-(1-0.2i)*u)--(.2u,-(1-0.2(i-1))*u);
	  thdraw (0,-(1-0.2i)*u)--(-.2u,-(1-0.2(i-1))*u);
	endfor;
enddef;

def p_station_temporary_AUT (expr pos)=
    T:=identity shifted pos;
    pickup PenD;
    thclean fullcircle scaled 0.15u;
    thdraw fullcircle scaled 0.15u;
enddef;

let p_station_painted_AUT = p_station_fixed_ASF ;
let p_station_fixed_AUT = p_station_fixed_ASF ;

def p_claychoke_AUT (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity rotated -theta aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thclean (-.4u,-.4u)--(.4u,-.4u)--(.4u,.4u)--(-.4u,.4u)--cycle;
    thdraw (-.4u,-.4u)--(.4u,-.4u)--(.4u,.4u)--(-.4u,.4u)--cycle;
    thdraw (-.15u,.3u)--(-.15u,-.25u)--(.15u,-.25u);
enddef;

def p_claytree_AUT (expr pos,theta,sc,al)=
    U:=(.55u,.6u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:= (-.15u,.15u)--(.0u,.6u)--(.15u,.15u);
    thdraw p ;
    thdraw p shifted (-.4u,-.3u);
    thdraw p shifted (.4u,-.2u) ;
enddef;




%%%%% ENDINPUT uAUT %%%%%





%%%%% INPUT uSBE %%%%%


% Symbol set of Brazilian Speleological Society (SBE - Sociedade Brasileira de
% Espeleologia), author Rodrigo Severo.


%%%%%%%%%%%%%%%%%%%%%%%%% Points %%%%%%%%%%%%%%%%%%%%%%%%%


picture SBE_altar_raw;
SBE_altar_raw := image(
	fill (406,482)..controls (364,491) and (340,542)..(360,581)
		..controls (378,621) and (436,633)..(469,603)
		..controls (504,575) and (500,514)..(461,491)
		..controls (445,480) and (425,478)..(406,482)
		--cycle;
	pickup pencircle scaled 99bp;
	draw (225,307)--(319,460);
	pickup pencircle scaled 70bp;
	draw (329,472)--(391,364)--(466,419);
	draw (154,188)--(326,188)--(224,290);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_altar_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_altar_raw;
enddef;


picture SBE_archeo_excavation_raw;
SBE_archeo_excavation_raw := image(
	begingroup;
		fill (199,415)--(242,555)--(312,574)
			--(329,558)--(351,580)--(335,597)
			--(422,683)--(466,640)--(379,553)
			--(362,569)--(340,547)--(359,528)
			--(339,457)--cycle;
		pickup pencircle scaled 17bp;
		interim linecap := rounded;
		draw (138,464)..controls (152,460) and (169,461)..(187,461);
		draw (368,463)..controls (411,458) and (449,461)..(489,464);
		pickup pencircle scaled 11bp;
		interim linecap := squared;
		draw (291,403)..controls (279,402) and (262,395)..(253,372);
		draw (371,409)..controls (370,422) and (359,429)..(346,430);
		draw (423,399)..controls (432,402) and (437,411)..(437,418);
		currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
	endgroup;
);

def p_archeoexcavation_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_archeo_excavation_raw;
enddef;


picture SBE_audio_raw;
SBE_audio_raw := image(
	fill (125,196)--(81,171)--(44,171)
		..controls (34,171) and (27,163)..(27,154)
		--(27,115)..controls (27,106) and (34,98)..(44,98)
		--(81,98)--(125,73)..controls (133,68) and (140,72)..(140,81)
		--(140,188)..controls (140,197) and (133,201)..(125,196)
		--cycle;
	pickup pencircle scaled 11bp;
	draw (158,186)..controls (178,152) and (179,118)..(158,82);
	draw (185,202)..controls (208,166) and (213,112)..(185,67);
	draw (213,218)..controls (248,150) and (243,105)..(213,50);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_audio_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_audio_raw;
enddef;


picture SBE_bat_raw;
SBE_bat_raw := image(
	fill (538,34)..controls (484,144) and (350,326)..(287,197)
		..controls (249,375) and (141,347)..(83,352)
		..controls (58,356) and (10,339)..(53,371)
		..controls (100,409) and (147,451)..(204,474)
		..controls (286,503) and (318,471)..(376,407)
		..controls (439,342) and (510,278)..(599,252)
		..controls (601,278) and (580,480)..(623,338)
		..controls (621,373) and (696,393)..(707,345)
		..controls (719,377) and (741,417)..(737,370)
		..controls (732,310) and (745,281)..(749,252)
		..controls (837,323) and (902,458)..(1017,478)
		..controls (1114,499) and (1201,436)..(1266,371)
		..controls (1285,353) and (1316,330)..(1270,343)
		..controls (1174,357) and (1033,396)..(1018,231)
		..controls (905,326) and (818,126)..(798,41)
		..controls (718,124) and (662,-13)..(637,34)
		..controls (621,76) and (562,52)..(538,34)
		--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_bat_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_bat_raw;
enddef;


picture SBE_bones_raw;
SBE_bones_raw := image(
	fill (328,272)..controls (258,226) and (188,192)..(132,134)
		..controls (119,115) and (103,80)..(80,78)
		..controls (68,76) and (49,83)..(39,93)
		..controls (35,97) and (15,102)..(25,118)
		..controls (44,150) and (30,150)..(18,154)
		..controls (6,159) and (-2,159)..(-3,168)
		..controls (2,202) and (32,206)..(54,205)
		..controls (83,204) and (94,199)..(126,215)
		..controls (148,226) and (183,243)..(278,300)
		--cycle;
	fill (663,585)..controls (648,585) and (632,579)..(620,571)
		..controls (609,563) and (597,547)..(587,527)
		..controls (571,497) and (555,479)..(529,463)
		..controls (506,448) and (493,443)..(445,412)
		--(501,378)..controls (544,403) and (605,415)..(650,416)
		..controls (671,416) and (672,416)..(683,422)
		..controls (708,436) and (714,455)..(701,474)
		..controls (674,489) and (653,488)..(674,511)
		..controls (686,524) and (702,548)..(698,562)
		..controls (692,578) and (679,585)..(663,585)
		--cycle;
	fill (584,155)..controls (572,180) and (570,192)..(541,213)
		..controls (506,237) and (222,404)..(158,436)
		..controls (118,456) and (92,463)..(43,466)
		..controls (22,468) and (21,468)..(10,474)
		..controls (-12,490) and (-17,510)..(-3,527)
		..controls (23,541) and (45,538)..(25,563)
		..controls (15,576) and (0,601)..(5,615)
		..controls (19,647) and (61,636)..(83,619)
		..controls (93,610) and (104,593)..(114,572)
		..controls (127,542) and (142,523)..(166,505)
		..controls (205,477) and (361,387)..(421,358)
		..controls (480,330) and (597,259)..(609,256)
		..controls (631,255) and (670,257)..(683,238)
		..controls (690,228) and (693,208)..(690,195)
		..controls (688,189) and (693,170)..(674,171)
		..controls (637,172) and (644,159)..(646,147)
		..controls (648,134) and (652,126)..(644,121)
		..controls (612,110) and (594,134)..(584,155)
		--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_bones_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_bones_raw;
enddef;


def p_curtains_UIS(expr pos, theta, sc, al) =
	U := (.3u, .8u);
	pickup PenC;
	for i=-1 upto 1:
		T := identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
		thdraw (0,.15u)--(0,0){dir 180}..(-.12u,-.11u)..{dir 0}(0,-.22u)--(0,-.4u);
	endfor;
enddef;


picture SBE_danger_raw;
SBE_danger_raw := image(
	fill (331,489)..controls (330,489) and (328,489)..(326,488)
		--(291,422)..controls (291,422) and (291,421)..(291,421)
		..controls (291,417) and (294,414)..(297,413)
		--(365,413)..controls (369,414) and (371,417)..(371,421)
		..controls (371,422) and (371,422)..(371,423)
		--(336,488)..controls (335,489) and (333,489)..(331,489)
		..controls (331,489) and (331,489)..(331,489)
		--cycle withcolor red;
	fill (336,427)..controls (336,430) and (334,432)..(331,432)
		..controls (328,432) and (326,430)..(326,427)
		..controls (326,424) and (328,422)..(331,422)
		..controls (334,422) and (336,424)..(336,427)
		--cycle withcolor white;
	fill (335,464)..controls (336,466) and (332,466)..(331,466)
		..controls (330,466) and (327,466)..(327,464)
		--(330,436)..controls (330,435) and (330,435)..(331,435)
		..controls (332,435) and (332,435)..(332,436)
		--cycle withcolor white;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_danger_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_danger_raw;
enddef;


def p_discpillar_UIS(expr pos,theta,sc,al) =
	U := (.15u, .4u);
	T := identity rotated theta aligned al scaled sc shifted pos;
	pickup PenC;
	thdraw (-.15u,.4u) -- (0,.15u) -- (0,-.15u) -- (-.15u,-.4u);
	thdraw (0,-.15u) -- (.15u,-.4u);
	thdraw (0,.15u) -- (.15u,.4u);
	thdraw (-.15u,0) -- (.15u,0);
enddef;


def p_discpillars_UIS(expr pos,theta,sc,al) =
	U := (.3u, .8u);
	pickup PenC;
	for i=-1 upto 1:
		T := identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		thdraw (-.15u,.4u) -- (0,.15u) -- (0,-.15u) -- (-.15u,-.4u);
		thdraw (0,-.15u) -- (.15u,-.4u);
		thdraw (0,.15u) -- (.15u,.4u);
		thdraw (-.15u,0) -- (.15u,0);
	endfor;
enddef;


def p_discstalactites_UIS(expr pos,theta,sc,al) =
	U := (.3u, .8u);
	pickup PenC;
	for i=-1 upto 1:
		T := identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
		thdraw (0,.15u) -- (.15u,.4u);
		thdraw (-.15u,-.1u) -- (.15u,-.1u);
	endfor;
enddef;


def p_discstalagmites_UIS(expr pos,theta,sc,al) =
	U := (.3u, .8u);
	pickup PenC;
	for i=-1 upto 1:
		T := identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
		thdraw (0,-.15u) -- (.15u,-.4u);
		thdraw (-.15u,.1u) -- (.15u,.1u);
	endfor;
enddef;


def p_discstalactite_UIS(expr pos,theta,sc,al) =
	U := (.15u, .4u);
	T := identity rotated theta aligned al scaled sc shifted pos;
	pickup PenC;
	thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
	thdraw (0,.15u) -- (.15u,.4u);
	thdraw (-.15u,-.1u) -- (.15u,-.1u);
enddef;


def p_discstalagmite_UIS(expr pos,theta,sc,al) =
	U := (.15u, .4u);
	T := identity rotated theta aligned al scaled sc shifted pos;
	pickup PenC;
	thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
	thdraw (0,-.15u) -- (.15u,-.4u);
	thdraw (-.15u,.1u) -- (.15u,.1u);
enddef;


picture SBE_electric_light_raw;
SBE_electric_light_raw := image(
	begingroup;
		fill (334,564)..controls (341,561) and (346,556)..(349,550)
			..controls (350,548) and (351,546)..(351,543)
			..controls (349,543) and (347,543)..(345,543)
			..controls (329,543) and (313,543)..(296,543)
			..controls (294,545) and (296,548)..(297,550)
			..controls (300,556) and (305,561)..(312,564)
			..controls (317,567) and (324,567)..(330,565)
			..controls (332,565) and (333,565)..(334,564)
			--cycle;
		fill (394,393)..controls (402,379) and (406,361)..(404,344)
			..controls (399,312) and (375,287)..(348,280)
			..controls (317,271) and (282,283)..(263,310)
			..controls (246,333) and (244,370)..(258,391)
			..controls (277,419) and (281,466)..(281,466)
			--(368,466)..controls (369,439) and (383,413)..(394,393)
			--cycle;
		pickup pencircle scaled 25bp;
		draw (153,248)--(224,303);
		draw (489,255)--(424,301);
		draw (408,208)--(377,259);
		draw (241,218)--(266,265);
		draw (324,161)--(324,245);
		pickup pencircle scaled 22bp;
		interim linecap := rounded;
		draw (282,489)--(370,489);
		draw (280,524)--(371,524);
		currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
	endgroup;
);

def p_electriclight_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_electric_light_raw;
enddef;


picture SBE_exvoto_raw;
SBE_exvoto_raw := image(
	pickup pencircle scaled 29bp;
	draw (274,659)--(381,623);
	draw (209,277)--(247,393);
	draw (187,282)--(228,270);
	draw (297,647)--(224,427)--(247,393)
		--(283,408)--(357,631);
	draw (251,497)--(302,494);
	draw (490,657)--(578,587);
	draw (297,321)--(373,417);
	draw (282,334)--(313,309);
	draw (508,638)--(363,457)--(373,417)
		--(412,418)--(558,602);
	draw (421,524)--(452,482);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_exvoto_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_exvoto_raw;
enddef;


picture SBE_gate_raw;
SBE_gate_raw := image(
	begingroup;
		pickup pencircle scaled 28bp;
		interim linecap := butt;
		interim linejoin := rounded;
		draw (121,221)--(249,244)--(249,546)
			--(121,454)--cycle;
		draw (466,221)--(337,244)--(337,546)
			--(465,454)--cycle;
		pickup pencircle scaled 22bp;
		interim linejoin := mitered;
		draw (121,307)--(249,330);
		draw (184,496)--(184,234);
		draw (466,307)--(337,330);
		draw (402,496)--(402,234);
		currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
	endgroup;
);

def p_gate_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_gate_raw;
enddef;


def p_helictites_UIS(expr pos,theta,sc,al) =
	U:=(.4u,.8u);
	pickup PenC;
	for i=-1 upto 1:
		if i < 0:
			T:=identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .45u, abs(i) * .15u));
		else:
			T:=identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		fi;
		thdraw (0,.4u)--(0,-.4u);
		p := (-.2u,.4u)---(-.2u,.1u){down}..{dir -10}(-.1u,0.02u)---origin;
		thdraw p;
		thdraw p reflectedabout (origin,(0,u)) reflectedabout (origin,(u,0));
	endfor;
enddef;


picture SBE_human_bones_raw;
SBE_human_bones_raw := image(
	fill (52,279)..controls (50,279) and (48,279)..(47,278)
		--(47,278)..controls (37,276) and (32,266)..(33,258)
		..controls (26,254) and (20,247)..(20,240)
		..controls (20,230) and (30,221)..(41,221)
		..controls (45,222) and (49,223)..(52,225)
		--(88,205)..controls (88,205) and (88,206)..(87,206)
		--(86,210)..controls (82,221) and (81,236)..(82,251)
		--(72,257)..controls (72,261) and (71,265)..(70,268)
		..controls (66,275) and (59,279)..(52,279)
		--cycle;
	fill (258,151)..controls (256,139) and (255,125)..(249,113)
		--(296,87)..controls (295,79) and (300,71)..(306,67)
		..controls (323,63) and (335,72)..(335,86)
		..controls (342,90) and (347,97)..(347,104)
		..controls (347,114) and (337,123)..(326,122)
		..controls (322,122) and (319,121)..(315,119)
		--cycle;
	fill (316,279)..controls (309,279) and (302,275)..(298,268)
		..controls (296,265) and (296,261)..(296,257)
		--(291,254)..controls (293,239) and (292,221)..(288,210)
		--(288,209)--(315,225)..controls (319,223) and (322,222)..(327,221)
		..controls (338,221) and (347,230)..(347,240)
		..controls (347,247) and (342,254)..(335,258)
		..controls (335,266) and (331,276)..(321,278)
		--(321,278)..controls (319,279) and (318,279)..(316,279)
		--cycle;
	fill (116,155)--(52,119)..controls (49,121) and (46,122)..(41,122)
		..controls (30,123) and (20,114)..(20,104)
		..controls (20,97) and (25,90)..(33,86)
		..controls (32,72) and (44,63)..(62,67)
		..controls (67,71) and (72,79)..(72,87)
		--(123,116)..controls (118,128) and (117,143)..(116,155)
		--cycle;
	fill (187,311)..controls (179,311) and (171,310)..(165,308)
		..controls (136,296) and (120,285)..(109,255)
		..controls (105,242) and (105,223)..(109,211)
		--(110,208)..controls (119,188) and (127,188)..(129,184)
		..controls (135,174) and (130,139)..(148,126)
		..controls (156,124) and (165,119)..(171,120)
		..controls (176,122) and (182,120)..(187,120)
		..controls (192,120) and (198,121)..(203,120)
		..controls (211,120) and (218,123)..(226,126)
		..controls (244,139) and (239,174)..(245,184)
		..controls (246,188) and (255,188)..(263,208)
		--(265,211)..controls (269,223) and (269,242)..(265,255)
		..controls (265,255) and (259,272)..(249,282)
		..controls (236,295) and (230,302)..(209,308)
		..controls (203,310) and (195,311)..(187,311)
		--cycle;
	fill (171,230)..controls (162,217) and (161,207)..(148,207)
		..controls (125,206) and (126,224)..(125,231)
		..controls (123,240) and (136,248)..(148,248)
		..controls (159,248) and (176,239)..(171,230)
		--cycle withcolor white;
	fill (203,230)..controls (212,217) and (212,207)..(226,207)
		..controls (249,206) and (247,224)..(249,231)
		..controls (251,240) and (238,248)..(226,248)
		..controls (215,248) and (198,239)..(203,230)
		--cycle withcolor white;
	fill (187,212)..controls (177,207) and (175,183)..(175,174)
		..controls (175,174) and (176,173)..(177,173)
		..controls (186,178) and (189,178)..(198,173)
		..controls (199,173) and (200,174)..(200,174)
		..controls (200,183) and (197,213)..(187,212)
		--cycle withcolor white;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_humanbones_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_human_bones_raw;
enddef;


picture SBE_masonry_raw;
SBE_masonry_raw := image(
	begingroup;
		pickup pencircle scaled 28bp;
		interim linecap := butt;
		interim linejoin := mitered;
		draw (287,482)--(355,482);
		draw (247,442)--(315,442);
		draw (327,442)--(395,442);
		draw (206,401)--(275,401);
		draw (287,401)--(355,401);
		draw (247,360)--(315,360);
		draw (327,360)--(395,360);
		currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
	endgroup;
);

def p_masonry_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_masonry_raw;
enddef;


picture UIS_minus_raw;
UIS_minus_raw := image(
	pickup pencircle scaled 3bp;
	draw (383,401)--(403,401);
	pickup pencircle scaled 2bp;
	draw (407,401)..controls (407,394) and (401,387)..(393,387)
		..controls (385,387) and (379,394)..(379,401)
		..controls (379,409) and (385,415)..(393,415)
		..controls (401,415) and (407,409)..(407,401)
		--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_minus_UIS(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw UIS_minus_raw;
enddef;


picture SBE_mud_raw;
SBE_mud_raw := image(
	fill (240,321)..controls (232,352) and (217,388)..(183,397)
		..controls (156,398) and (135,369)..(108,381)
		..controls (82,388) and (66,417)..(74,442)
		..controls (78,479) and (59,518)..(79,552)
		..controls (87,582) and (41,598)..(52,628)
		..controls (68,653) and (99,634)..(121,630)
		..controls (147,623) and (162,645)..(172,664)
		..controls (200,685) and (236,674)..(267,676)
		..controls (290,675) and (312,676)..(333,685)
		..controls (352,692) and (380,696)..(394,676)
		..controls (406,653) and (421,627)..(450,623)
		..controls (474,620) and (506,635)..(520,605)
		..controls (536,576) and (533,543)..(533,512)
		..controls (531,476) and (511,442)..(521,407)
		..controls (523,374) and (483,370)..(459,370)
		..controls (431,371) and (407,359)..(382,348)
		..controls (357,337) and (326,324)..(300,340)
		..controls (277,343) and (264,298)..(241,320)
		--(240,320)--cycle withcolor (0.53, 0.24, 0.02);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_mud_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_mud_raw;
enddef;


picture SBE_mudcrack_raw;
SBE_mudcrack_raw := image(
	fill (320,501)--(340,468)--(320,462)
		--(320,462)--(320,457)--(348,464)
		--(387,451)--(371,434)--(345,421)
		--(320,427)--(320,427)--(320,424)
		--(331,422)--(320,385)--(325,385)
		--(335,422)--(344,418)--(351,385)
		--(355,385)--(355,385)--(348,419)
		--(373,429)--(401,403)--(393,388)
		--(395,385)--(397,385)--(396,387)
		--(403,402)--(416,400)--(428,389)
		--(429,390)--(417,404)--(403,404)
		--(378,432)--(393,448)--(431,415)
		--(436,415)--(436,419)--(433,419)
		--(396,452)--(406,464)--(436,460)
		--(436,464)--(408,468)--(403,484)
		--(436,490)--(436,493)--(403,488)
		--(403,501)--(399,501)--(400,483)
		--(403,468)--(391,457)--(351,467)
		--(378,501)--(370,501)--(346,468)
		--(324,501)--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_mudcrack_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_mudcrack_raw;
enddef;


picture SBE_nameplate_raw;
SBE_nameplate_raw := image(
	pickup pencircle scaled 24bp;
	draw (77,563)--(505,563)--(505,340)
		--(77,340)--cycle;
	pickup pencircle scaled 10bp;
	draw (208,496)--(422,496);
	draw (117,450)--(358,450);
	draw (264,401)--(470,401);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_nameplate_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_nameplate_raw;
enddef;


picture SBE_wheelchair_raw;
SBE_wheelchair_raw := image(
	fill (363,192)..controls (363,97) and (286,20)..(192,20)
		..controls (97,20) and (20,97)..(20,192)
		..controls (20,287) and (97,364)..(192,364)
		..controls (286,364) and (363,287)..(363,192)
		--cycle withcolor white;
	pickup pencircle scaled 39bp;
	draw (363,192)..controls (363,97) and (286,20)..(192,20)
		..controls (97,20) and (20,97)..(20,192)
		..controls (20,287) and (97,364)..(192,364)
		..controls (286,364) and (363,287)..(363,192)
		--cycle withcolor red;
	fill (202,301)..controls (202,286) and (190,274)..(175,274)
		..controls (160,274) and (148,286)..(148,301)
		..controls (148,316) and (160,328)..(175,328)
		..controls (190,328) and (202,316)..(202,301)
		--cycle;
	pickup pencircle scaled 21bp;
	draw (139,221)..controls (109,212) and (88,184)..(88,152)
		..controls (88,113) and (120,81)..(160,81)
		..controls (192,81) and (221,102)..(229,133);
	draw (177,254)--(177,178)--(259,178)
		--(278,129)--(299,134);
	draw (177,233)--(239,233);
);

picture SBE_nowheelchair_raw;
SBE_nowheelchair_raw := image(
	draw SBE_wheelchair_raw;
	begingroup;
		pickup pencircle scaled 30bp;
		interim linecap := butt;
		interim linejoin := mitered;
		draw (60,307)--(323,77) withcolor red;
	endgroup;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_nowheelchair_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_nowheelchair_raw;
enddef;


picture SBE_pendant_raw;
SBE_pendant_raw := image(
	pickup pencircle scaled 22bp;
	draw (476,639)..controls (471,639) and (422,621)..(428,575)
		..controls (434,533) and (506,503)..(505,457)
		..controls (502,260) and (383,164)..(289,164)
		..controls (196,164) and (77,260)..(73,457)
		..controls (72,503) and (144,533)..(150,575)
		..controls (156,621) and (107,639)..(102,639);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_pendant_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_pendant_raw;
enddef;


def p_pillarwithcurtains_UIS(expr pos, theta, sc, al) =
	U := (.15u,.5u);
	T := identity rotated theta aligned al scaled sc shifted pos;
	pickup PenC;
	thdraw (0,.25u)--(0,.1u){dir 180}..(-.1u,0)..{dir 0}(0,-.1u)--(0,-.25u);
	thdraw (-.15u,-.5u)--(0,-.25u)--(.15u,-.5u);
	thdraw (-.15u,.5u)--(0,.25u)--(.15u,.5u);
enddef;


def p_pillarswithcurtains_UIS(expr pos, theta, sc, al) =
	U := (.3u,u);
	pickup PenC;
	pickup PenC;
	for i=-1 upto 1:
		T := identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		thdraw (0,.25u)--(0,.1u){dir 180}..(-.1u,0)..{dir 0}(0,-.1u)--(0,-.25u);
		thdraw (-.15u,-.5u)--(0,-.25u)--(.15u,-.5u);
		thdraw (-.15u,.5u)--(0,.25u)--(.15u,.5u);
	endfor;
enddef;


picture SBE_photo_raw;
SBE_photo_raw := image(
	fill (186,476)--(186,445)--(111,445)
		--(75,408)--(75,302)--(188,302)
		--(188,286)--(329,286)--(329,302)
		--(440,302)--(440,408)--(405,445)
		--(328,445)--(328,476)--cycle;
	pickup pencircle scaled 18bp;
	draw (194,499)--(107,621);
	draw (320,499)--(407,621);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_photo_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_photo_raw;
enddef;


picture UIS_plus_raw;
UIS_plus_raw := image(
	pickup pencircle scaled 3bp;
	draw (383,401)--(403,401);
	draw (393,411)--(393,392);
	pickup pencircle scaled 2bp;
	draw (407,401)..controls (407,394) and (401,387)..(393,387)
		..controls (385,387) and (379,394)..(379,401)
		..controls (379,409) and (385,415)..(393,415)
		..controls (401,415) and (407,409)..(407,401)
		--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_plus_UIS(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw UIS_plus_raw;
enddef;


picture UIS_plusminus_raw;
UIS_plusminus_raw := image(
	pickup pencircle scaled 3bp;
	draw (383,427)--(403,427);
	draw (393,418)--(393,437);
	draw (383,401)--(403,401);
	pickup pencircle scaled 2bp;
	draw (393,387)..controls (385,387) and (379,394)..(379,401)
		--(379,427)..controls (379,435) and (385,441)..(393,441)
		..controls (401,441) and (407,435)..(407,427)
		--(407,401)..controls (407,394) and (401,387)..(393,387)
		--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / (xpart urcorner currentpicture) - (xpart llcorner currentpicture));
);

def p_plusminus_UIS(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw UIS_plusminus_raw;
enddef;


picture SBE_seed_germination_raw;
SBE_seed_germination_raw := image(
	fill (443,464)..controls (441,492) and (411,512)..(389,501)
		..controls (406,574) and (355,622)..(378,509)
		..controls (350,513) and (331,473)..(333,452)
		..controls (350,440) and (374,461)..(381,474)
		..controls (382,466) and (417,441)..(443,464)
		--cycle;
	pickup pencircle scaled 25bp;
	draw (101,276)..controls (177,243) and (396,296)..(502,269);
	pickup pencircle scaled 19bp;
	draw (194,270)..controls (160,669) and (364,759)..(382,543);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_seedgermination_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_seed_germination_raw;
enddef;


def p_stalactitestalagmite_UIS(expr pos,theta,sc,al) =
	U := (.15u, .4u);
	T := identity rotated theta aligned al scaled sc shifted pos;
	pickup PenC;
	thdraw (-.15u,.4u) -- (0,.2u) -- (.15u,.4u);
	thdraw (.15u,-.4u) -- (0,-.2u) -- (-.15u,-.4u);
	thdraw (0,-.2u) -- (0,-.1u);
	thdraw (0,.2u) -- (0,.1u);
enddef;


def p_stalactitesstalagmites_UIS(expr pos,theta,sc,al) =
	U := (.3u, .8u);
	pickup PenC;
	for i=-1 upto 1:
		T := identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		thdraw (-.15u,.4u) -- (0,.2u) -- (.15u,.4u);
		thdraw (.15u,-.4u) -- (0,-.2u) -- (-.15u,-.4u);
		thdraw (0,-.2u) -- (0,-.1u);
		thdraw (0,.2u) -- (0,.1u);
	endfor;
enddef;


picture SBE_tree_trunk_raw;
SBE_tree_trunk_raw := image(
	pickup pencircle scaled 11bp;
	draw (338,554)--(153,393)..controls (64,292) and (204,143)..(312,243)
		--(504,488);
	pickup pencircle scaled 0.1bp;
	fill (313,318)..controls (313,274) and (277,238)..(232,238)
		..controls (188,238) and (152,274)..(152,318)
		..controls (152,363) and (188,398)..(232,398)
		..controls (277,398) and (313,363)..(313,318)
		--cycle;
	pickup pencircle scaled 5bp;
	draw (290,453)--(348,506);
	draw (375,406)--(445,481);
	draw (316,397)--(348,429);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_treetrunk_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_tree_trunk_raw;
enddef;


picture SBE_volcano_raw;
SBE_volcano_raw := image(
	pickup pencircle scaled 21bp;
	draw (36,222)--(169,567)..controls (177,510) and (212,485)..(265,485)
		..controls (319,485) and (353,510)..(361,567)
		--(494,222);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_volcano_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_volcano_raw;
enddef;


picture SBE_walkway_raw;
SBE_walkway_raw := image(
	begingroup;
		pickup pencircle scaled 9bp;
		interim linecap := butt;
		interim linejoin := mitered;
		draw (19,26)--(171,26);
		draw (135,61)--(171,61);
		draw (19,61)--(55,61);
		draw (89,61)--(104,61);
		pickup pencircle scaled 12bp;
		interim linecap := rounded;
		draw (63,43)--(79,72)--(93,135);
		draw (124,44)--(115,72)--(93,97)
			--(100,133);
		pickup pencircle scaled 9bp;
		interim linejoin := rounded;
		draw (133,109)--(115,117)--(99,144)
			--(72,128)--(62,107);
		pickup pencircle scaled 0.1bp;
		fill (113,162)..controls (113,157) and (108,152)..(102,152)
			..controls (96,152) and (91,157)..(91,162)
			..controls (91,168) and (96,173)..(102,173)
			..controls (108,173) and (113,168)..(113,162)
			--cycle;
	endgroup;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_walkway_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_walkway_raw;
enddef;


picture SBE_water_drip_raw;
SBE_water_drip_raw := image(
	fill (493,1196)..controls (535,1234) and (583,1266)..(635,1290)
		..controls (595,1233) and (566,1160)..(588,1091)
		..controls (622,981) and (733,912)..(757,796)
		..controls (789,684) and (728,556)..(622,509)
		..controls (524,461) and (398,489)..(328,572)
		..controls (278,629) and (259,710)..(272,785)
		..controls (293,942) and (375,1090)..(493,1196)
		--cycle;
	fill (495,1159)..controls (403,1066) and (329,950)..(299,821)
		..controls (287,761) and (285,694)..(314,637)
		..controls (354,571) and (425,522)..(502,512)
		..controls (513,511) and (550,509)..(522,518)
		..controls (449,551) and (384,613)..(366,694)
		..controls (342,794) and (371,898)..(411,990)
		..controls (441,1059) and (481,1123)..(524,1185)
		..controls (514,1177) and (505,1168)..(495,1159)
		--cycle withcolor white;
	fill (353,484)..controls (341,488) and (325,494)..(316,504)
		..controls (300,537) and (261,574)..(232,540)
		..controls (209,503) and (241,469)..(276,471)
		..controls (299,473) and (344,478)..(353,484)
		--cycle;
	fill (702,500)..controls (714,503) and (731,509)..(739,520)
		..controls (756,553) and (795,591)..(825,557)
		..controls (848,519) and (816,485)..(780,486)
		..controls (757,488) and (711,493)..(702,500)
		--cycle;
	fill (290,571)..controls (279,580) and (262,592)..(246,594)
		..controls (203,588) and (140,602)..(154,654)
		..controls (176,701) and (231,693)..(253,656)
		..controls (266,632) and (291,584)..(290,571)
		--cycle;
	fill (761,591)..controls (772,601) and (789,613)..(805,614)
		..controls (848,609) and (911,623)..(897,674)
		..controls (875,721) and (820,713)..(798,676)
		..controls (785,652) and (760,604)..(761,591)
		--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_waterdrip_SBE(expr pos, theta, sc, al) =
	T := identity aligned al rotated theta scaled sc shifted pos;
	thdraw SBE_water_drip_raw;
enddef;


def p_wheelchair_SBE(expr pos, theta, sc, al) =
	T := identity aligned al rotated theta scaled sc shifted pos;
	thdraw SBE_wheelchair_raw shifted (-(llcorner SBE_wheelchair_raw)-(urcorner SBE_wheelchair_raw - llcorner SBE_wheelchair_raw)/2) scaled (u / max((xpart urcorner SBE_wheelchair_raw) - (xpart llcorner SBE_wheelchair_raw), (ypart urcorner SBE_wheelchair_raw) - (ypart llcorner SBE_wheelchair_raw)));
enddef;


%%%%%%%%%%%%%%%%%%%%%%%%% Lines %%%%%%%%%%%%%%%%%%%%%%%%%


def l_abyssentrance_SBE(expr P) =
	begingroup
		path SBE_Tick, SBE_T;

		T := identity;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.5u); % symbol length nudged to be multiple of path length
		SBE_Tick := (0,0.1u) -- (0,-0.1u);
		SBE_T := (0,0) -- (0,-0.1u);
		pickup PenD;
		forever:
			t1 := arctime (cursor + elementSize * 1/8) of P;
			t2 := arctime (cursor + elementSize * 2/8) of P;
			t3 := arctime (cursor + elementSize * 4/8) of P;
			t4 := arctime (cursor + elementSize * 6/8) of P;
			t5 := arctime (cursor + elementSize * 7/8) of P;

			thdraw SBE_Tick rotated angle(thdir(P,t1)) shifted (point t1 of P);
			thdraw (subpath (t2,t4) of P);
			thdraw SBE_T rotated (180+angle(thdir(P,t3))) shifted (point t3 of P);
			thdraw SBE_Tick rotated angle(thdir(P,t5)) shifted (point t5 of P);

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;
	endgroup;
enddef;


def l_dripline_SBE(expr P) =
	begingroup
		path SBE_Tick;

		T := identity;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.5u); % symbol length nudged to be multiple of path length
		SBE_Tick := (0,0.1u) -- (0,-0.1u);
		pickup PenD;
		forever:
			t1 := arctime (cursor + elementSize * 1/8) of P;
			t2 := arctime (cursor + elementSize * 2/8) of P;
			t3 := arctime (cursor + elementSize * 4/8) of P;
			t4 := arctime (cursor + elementSize * 6/8) of P;
			t5 := arctime (cursor + elementSize * 7/8) of P;

			thdraw SBE_Tick rotated angle(thdir(P,t1)) shifted (point t1 of P);
			thdraw (subpath (t2,t4) of P);
			thdraw SBE_Tick rotated angle(thdir(P,t5)) shifted (point t5 of P);

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;
	endgroup;
enddef;


def l_fault_SBE(expr P) =
	begingroup
		path SBE_Dot;
		pair SBE_Ppb, SBE_Pdb, SBE_Pvb, SBE_Ppe, SBE_Pde, SBE_Pve;

		T := identity;

		pickup PenA;
		thdraw P;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.5u); % symbol length nudged to be multiple of path length
		SBE_Dot := (0,-0.05u) -- (0,0.05u);
		pickup PenC;
		distance := 0.2u;
		forever:
			t0 := arctime (cursor + elementSize * 1/8) of P;
			t1 := arctime (cursor + elementSize * 5/8) of P;
			t2 := arctime (cursor + elementSize * 7/8) of P;

			SBE_Ppb := (point t0 of P);
			SBE_Pdb := unitvector(thdir(P,t0));
			SBE_Pvb := SBE_Pdb rotated -90;
			SBE_Ppe := (point t1 of P);
			SBE_Pde := unitvector(thdir(P,t1));
			SBE_Pve := SBE_Pde rotated -90;

			if cursor > 0:
				thdraw (SBE_Ppb - distance * SBE_Pvb) -- (SBE_Ppe - distance * SBE_Pve);
			fi;

			thdraw SBE_Dot rotated (angle(thdir(P,t2))+90) shifted (point t2 of P + distance * unitvector(thdir(P,t2) rotated 90));

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;
	endgroup;
enddef;


def l_joint_SBE(expr P) =
	T := identity;

	cursor := 0;
	totalLength := arclength P;
	elementSize := adjust_step(totalLength, u); % symbol length nudged to be multiple of path length
	pickup PenC;
	forever:
		t0 := arctime (cursor + elementSize * 3/22) of P;
		t1 := arctime (cursor + elementSize * 10/22) of P;
		t2 := arctime (cursor + elementSize * 16/22) of P;
		t3 := arctime (cursor + elementSize * 19/22) of P;

		thdraw (subpath (t0,t1) of P);
		thdraw (subpath (t2,t3) of P);

		cursor := cursor + elementSize;
		exitif cursor > totalLength - (elementSize / 2);
	endfor;
enddef;


def l_lowceiling_SBE(expr P) =
	begingroup
		path SBE_T;

		T := identity;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.5u); % symbol length nudged to be multiple of path length
		SBE_T := (0,0) -- (0,-0.1u);
		pickup PenD;
		forever:
			t1 := arctime (cursor + elementSize * 1/7) of P;
			t2 := arctime (cursor + elementSize * 3/7) of P;
			t3 := arctime (cursor + elementSize * 4/7) of P;
			t4 := arctime (cursor + elementSize * 6/7) of P;

			thdraw (subpath (t1,t4) of P);
			thdraw SBE_T rotated (180+angle(thdir(P,t2))) shifted (point t2 of P);
			thdraw SBE_T rotated (180+angle(thdir(P,t3))) shifted (point t3 of P);

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;
	endgroup;
enddef;


def l_pitchimney_SBE(expr P) =
	begingroup
		path SBE_Tsmall, SBE_Tlarge;

		T := identity;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.5u); % symbol length nudged to be multiple of path length
		SBE_Tsmall := (0,0) -- (0,-0.1u);
		SBE_Tlarge := (0,0) -- (0,-0.175u);
		pickup PenD;
		forever:
			t1 := arctime (cursor + elementSize * 1/6) of P;
			t2 := arctime (cursor + elementSize * 2/6) of P;
			t3 := arctime (cursor + elementSize * 3/6) of P;
			t4 := arctime (cursor + elementSize * 4/6) of P;
			t5 := arctime (cursor + elementSize * 5/6) of P;

			thdraw (subpath (t1,t5) of P);

			thdraw SBE_Tsmall rotated (180+angle(thdir(P,t2))) shifted (point t2 of P);
			thdraw SBE_Tlarge rotated (180+angle(thdir(P,t3))) shifted (point t3 of P);
			thdraw SBE_Tsmall rotated (180+angle(thdir(P,t4))) shifted (point t4 of P);

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;
	endgroup;
enddef;


def l_rimstonedam_SBE(expr P) =
	cas := 0;
	distance := arclength P;
	mystep := adjust_step(distance, 0.9u);
	pickup PenC;
	forever:
		t  := arctime (cas + mystep/2) of P;
		T := identity rotated angle(thdir(P,t)) scaled 0.7 shifted (point t of P);
		thdraw (-.45u,.2u){dir -80}..{dir -50}(-.15u,0){dir 30}..{dir -30}(.15u,.1u){dir -50}..{dir 70}(.45u,.2u);
		cas := cas + mystep;
		exitif cas > distance - (2*mystep/3); % for rounding errors
	endfor;
enddef;


def l_rimstonepool_SBE(expr P) =
	cas := 0;
	distance := arclength P;
	mystep := adjust_step(distance, 0.9u);
	pickup PenC;
	forever:
		t  := arctime (cas + mystep/2) of P;
		T := identity rotated angle(thdir(P,t)) scaled 0.7 shifted (point t of P);
		p := (-.45u,.2u){dir -80}..{dir -50}(-.15u,-.1u){dir 30}..{dir -30}(.15u,.1u){dir -50}..{dir 70}(.45u,.2u);
		thfill buildcycle(p,((.5u,.15u)--(-.5u,.15u)));
		thdraw p;
		cas := cas + mystep;
		exitif cas > distance - (2*mystep/3); % for rounding errors
	endfor;
enddef;


def l_walkway_SBE(expr P) =
	begingroup
		pair SBE_da, SBE_db, SBE_pa, SBE_pb, SBE_ta, SBE_tb, SBE_tc, SBE_td;

		T := identity;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.2u); % symbol length nudged to be multiple of path length
		distance := 0.1u;

		pickup PenD;
		forever:
			t1 := arctime (cursor + elementSize * 1/5) of P;
			t2 := arctime (cursor + elementSize * 4/5) of P;

			SBE_pa := point t1 of P;
			SBE_pb := point t2 of P;

			SBE_da := unitvector(thdir(P,t1)) * distance;
			SBE_db := unitvector(thdir(P,t2)) * distance;

			SBE_ta := SBE_pa + (SBE_da rotated 90);
			SBE_tb := SBE_pb + (SBE_db rotated 90);
			SBE_tc := SBE_pa + (SBE_da rotated -90);
			SBE_td := SBE_pb + (SBE_db rotated -90);

			thdraw SBE_ta -- SBE_tb;
			thdraw SBE_tc -- SBE_td;

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;
	endgroup;
enddef;


%%%%%%%%%%%%%%%%%%%%%%%%% Areas %%%%%%%%%%%%%%%%%%%%%%%%%


picture SBE_a_mudcrack_raw;
SBE_a_mudcrack_raw := image(
	begingroup;
		interim linecap := butt;
		interim linejoin := mitered;
		pickup pencircle scaled 8bp;
		draw (172,466)--(225,425)--(271,440)
			--(323,390)--(346,423)--(414,363)
			--(390,275)--(414,281)--(438,322);
		pickup pencircle scaled 4bp;
		draw (244,252)--(232,272)--(308,293)
			--(257,310)--(266,357)--(291,380)
			--(303,428)--(282,477)--(393,502)
			--(380,518);
		pickup pencircle scaled 6bp;
		draw (172,466)--(244,518);
		pickup pencircle scaled 8bp;
		draw (173,322)--(205,357)--(244,322)
			--(266,357);
		pickup pencircle scaled 8bp;
		draw (380,252)--(364,292)--(380,322)
			--(346,423)--(417,491)--(393,502);
		pickup pencircle scaled 8bp;
		draw (437,466)--(417,491)--(380,392);
		currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (1.5u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
	endgroup;
);

beginpattern(pattern_mudcrack_SBE);
	draw SBE_a_mudcrack_raw;
endpattern;

def a_mudcrack_SBE(expr Path) =
	T := identity;
	thclean Path;
	thfill Path withpattern pattern_mudcrack_SBE;
enddef;


def pillar_main_SBE(expr P) =
	begingroup
		rgbcolor SBE_Orange;
		pair SBE_d, SBE_p;

		T := identity;

		SBE_Orange := (1, 0.6, 0);

		pickup PenD;
		thfill P withcolor SBE_Orange;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.01u); % symbol length nudged to be multiple of path length
		borderWidth := 0.3u;

		pickup PenA;
		forever:
			t1 := arctime (cursor + elementSize / 2) of P;

			SBE_p := point t1 of P;

			SBE_d := unitvector(thdir(P,t1)) * borderWidth;

			thdraw SBE_p -- SBE_p + (SBE_d rotated 90) withcolor white;;

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;

		pickup PenA;
		thdraw P withcolor SBE_Orange;
	endgroup;
enddef;

def a_pillar_SBE(expr P) =
	picture SBE_Pillar;

	SBE_Pillar := image(pillar_main_SBE(P));

	thdraw SBE_Pillar;
enddef;


def a_pillarwithcurtains_SBE(expr P) =
	begingroup
		picture SBE_Pillar;
		path SBE_Curtain;

		SBE_Pillar := image(pillar_main_SBE(P));

		thdraw SBE_Pillar;

		SBE_Curtain := (0,-.4u){dir 180}..(-0.1u,-0.3u)..{dir 0}(0,-0.2u)..(0.1u,-0.1u)..{dir -180}(0,0);
		SBE_Curtain := SBE_Curtain scaled (0.2 / 0.4);
		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.5u); % symbol length nudged to be multiple of path length

		pickup PenD;
		forever:
			t1 := arctime (cursor + elementSize / 2) of P;

			thdraw SBE_Curtain rotated (180+angle(thdir(P,t1))) shifted (point t1 of P) withcolor (1,0.6,0);

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 3);
		endfor;
	endgroup;
enddef;


def a_stalactite_SBE(expr P) =
	T := identity;

	pickup PenA;
	thfill P withcolor (1, 0.9, 0.67);
	thdraw P withcolor (1, 0.6, 0);
enddef;


def a_stalactitestalagmite_SBE(expr P) =
	begingroup
		rgbcolor SBE_Orange, SBE_LightOrange;

		picture SBE_PicFill, SBE_PicDraw;
		path SBE_bboxP, SBE_clipFill, SBE_clipDraw;

		T := identity;

		SBE_LightOrange := (1, 0.9, 0.67);
		SBE_Orange := (1, 0.6, 0);
		SBE_bboxP := bbox P;
		SBE_clipFill := ulcorner SBE_bboxP -- llcorner SBE_bboxP -- lrcorner SBE_bboxP -- cycle;
		SBE_clipDraw := ulcorner SBE_bboxP -- urcorner SBE_bboxP -- lrcorner SBE_bboxP -- cycle;

		pickup PenA;
		thclean P;

		SBE_PicFill := image(
			fill P withcolor SBE_Orange;
			draw P withcolor SBE_Orange;
		);
		clip SBE_PicFill to SBE_clipFill;
		drawoptions();
		draw SBE_PicFill;

		SBE_PicDraw := image(
			fill P withcolor SBE_LightOrange;
			draw P withcolor SBE_Orange;
		);
		clip SBE_PicDraw to SBE_clipDraw;
		drawoptions();
		draw SBE_PicDraw;
	endgroup;
enddef;


def a_stalagmite_SBE(expr P) =
	T := identity;

	pickup PenA;
	thfill P withcolor (1, 0.6, 0);
enddef;



%%%%% ENDINPUT uSBE %%%%%






%%%%% INPUT thTrans %%%%%


% default translations

let p_station_fixed = p_station_fixed_ASF;
let p_station_painted = p_station_painted_SKBB;
let p_station_natural = p_station_natural_ASF;
let p_station_temporary = p_station_temporary_ASF;

let p_waterflow_paleo = p_waterflow_paleo_UIS;
let p_waterflow_permanent = p_waterflow_permanent_UIS;
let p_waterflow_intermittent = p_waterflow_intermittent_UIS;

let p_stalactite = p_stalactite_UIS;
let p_stalagmite = p_stalagmite_UIS;
let p_pillar = p_pillar_UIS;
let p_icestalactite = p_icestalactite_AUT;
let p_icestalagmite = p_icestalagmite_AUT;
let p_icepillar = p_icepillar_AUT;
let p_curtain = p_curtain_UIS;
let p_helictite = p_helictite_UIS;
let p_sodastraw = p_sodastraw_UIS;
let p_crystal = p_crystal_UIS;
let p_flowstone = p_flowstone_UIS;
let p_moonmilk = p_moonmilk_UIS;
let p_wallcalcite = p_wallcalcite_UIS;
let p_popcorn = p_popcorn_UIS;
let p_disk = p_disk_UIS;
let p_gypsum = p_gypsum_NSS;
let p_aragonite = p_aragonite_NSS;
let p_cavepearl = p_cavepearl_SKBB;
let p_gypsumflower = p_gypsumflower_NSS;
let p_rimstonepool = p_rimstonepool_ASF;
let p_rimstonedam = p_rimstonedam_ASF;
let p_anastomosis = p_anastomosis_UIS;
let p_karren = p_karren_UIS;
let p_scallop = p_scallop_UIS;
let p_flute = p_flute_UIS;
let p_raft = p_raft_NSS;
let p_raftcone = p_raftcone_NSS;
let p_spring = p_spring_SKBB;
let p_sink = p_sink_SKBB;
let p_narrowend = p_narrowend_UIS;
let p_lowend = p_lowend_UIS;
let p_flowstonechoke = p_flowstonechoke_NSS;
let p_breakdownchoke = p_breakdownchoke_NSS;
let p_claychoke = p_claychoke_AUT;
let p_claytree = p_claytree_AUT;
let p_bedrock = p_bedrock_ASF;
let p_clay = p_clay_SKBB;
let p_sand = p_sand_UIS;
let p_pebbles = p_pebbles_UIS;
let p_debris = p_debris_UIS;
let p_blocks = p_blocks_UIS;
let p_water = p_water_UIS;
let p_ice = p_ice_UIS;
let p_snow = p_snow_SKBB;
let p_archeomaterial = p_archeomaterial_UIS;
let p_paleomaterial = p_paleomaterial_UIS;
let p_guano = p_guano_UIS;
let p_altar = p_altar_SBE;
let p_archeoexcavation = p_archeoexcavation_SBE;
let p_audio = p_audio_SBE;
let p_bat = p_bat_SBE;
let p_bones = p_bones_SBE;
let p_curtains = p_curtains_UIS;
let p_danger = p_danger_SBE;
let p_discpillar = p_discpillar_UIS;
let p_discpillars = p_discpillars_UIS;
let p_discstalactites = p_discstalactites_UIS;
let p_discstalagmites = p_discstalagmites_UIS;
let p_discstalactite = p_discstalactite_UIS;
let p_discstalagmite = p_discstalagmite_UIS;
let p_electriclight = p_electriclight_SBE;
let p_exvoto = p_exvoto_SBE;
let p_gate = p_gate_SBE;
let p_helictites = p_helictites_UIS;
let p_humanbones = p_humanbones_SBE;
let p_masonry = p_masonry_SBE;
let p_minus = p_minus_UIS;
let p_mud = p_mud_SBE;
let p_mudcrack = p_mudcrack_SBE;
let p_nameplate = p_nameplate_SBE;
let p_nowheelchair = p_nowheelchair_SBE;
let p_pendant = p_pendant_SBE;
let p_pillarwithcurtains = p_pillarwithcurtains_UIS;
let p_pillarswithcurtains = p_pillarswithcurtains_UIS;
let p_photo = p_photo_SBE;
let p_plus = p_plus_UIS;
let p_plusminus = p_plusminus_UIS;
let p_seedgermination = p_seedgermination_SBE;
let p_stalactitestalagmite = p_stalactitestalagmite_UIS;
let p_stalactitesstalagmites = p_stalactitesstalagmites_UIS;
let p_treetrunk = p_treetrunk_SBE;
let p_volcano = p_volcano_SBE;
let p_walkway = p_walkway_SBE;
let p_waterdrip = p_waterdrip_SBE;
let p_wheelchair = p_wheelchair_SBE;
let p_vegetabledebris = p_vegetabledebris_ASF;
let p_root = p_root_ASF;
let p_entrance = p_entrance_UIS;
let p_gradient = p_gradient_UIS;
let p_rope = p_rope_SKBB;
let p_fixedladder = p_fixedladder_SKBB;
let p_ropeladder = p_ropeladder_SKBB;
let p_steps = p_steps_SKBB;
let p_bridge = p_bridge_SKBB;
let p_traverse = p_traverse_SKBB;
let p_anchor = p_anchor_SKBB;
let p_camp = p_camp_SKBB;
let p_dig = p_dig_UIS;
let p_noequipment = p_noequipment_SKBB;
let p_sectionarrow = p_sectionarrow_SKBB;
let p_continuation = p_continuation_UIS;
let p_airdraught = p_airdraught_UIS;
let p_airdraught_winter = p_airdraught_winter_UIS;
let p_airdraught_summer = p_airdraught_summer_UIS;
let p_station = p_station_SKBB;
let p_handrail = p_handrail_SKBB;
let p_viaferrata = p_viaferrata_SKBB;
let p_stalactites = p_stalactites_UIS;
let p_stalagmites = p_stalagmites_UIS;
let p_pillars = p_pillars_UIS;
let l_abyssentrance = l_abyssentrance_SBE;
let l_dripline = l_dripline_SBE;
let l_fault = l_fault_SBE;
let l_joint = l_joint_SBE;
let l_lowceiling = l_lowceiling_SBE;
let l_pitchimney = l_pitchimney_SBE;
let l_rimstonedam = l_rimstonedam_SBE;
let l_rimstonepool = l_rimstonepool_SBE;
let l_walkway = l_walkway_SBE;

let l_wall_bedrock = l_wall_bedrock_UIS;
let l_wall_sand = l_wall_sand_SKBB;
let l_wall_clay = l_wall_clay_SKBB;
let l_wall_pebbles = l_wall_pebbles_SKBB;
let l_wall_debris = l_wall_debris_SKBB;
let l_wall_blocks = l_wall_blocks_SKBB;
let l_wall_ice = l_wall_ice_SKBB;
let l_wall_underlying = l_wall_underlying_UIS;
let l_wall_unsurveyed = l_wall_unsurveyed_SKBB;
let l_wall_presumed = l_wall_presumed_UIS;
%let l_wall_invisible = l_wall_invisible;
let l_wall_pit = l_wall_pit_AUT;
let l_wall_overlying = l_wall_overlying_AUT;
let l_wall_flowstone = l_wall_flowstone_AUT;
let l_wall_moonmilk = l_wall_moonmilk_AUT;

let l_waterflow_permanent = l_waterflow_permanent_UIS;
let l_waterflow_intermittent = l_waterflow_intermittent_SKBB;
let l_waterflow_conjectural = l_waterflow_conjectural_SKBB;

let l_border_visible = l_border_visible_SKBB;
let l_border_temporary = l_border_temporary_SKBB;
let l_border_presumed = l_border_presumed_SKBB;
%let l_border_invisible = l_border_invisible;

let l_floorstep = l_floorstep_UIS;
let l_pit = l_pit_UIS;
let l_ceilingstep = l_ceilingstep_SKBB;
let l_chimney = l_chimney_UIS;
let l_overhang = l_overhang_SKBB;
let l_slope = l_slope_SKBB;
let l_ceilingmeander = l_ceilingmeander_SKBB;
let l_floormeander = l_floormeander_SKBB;
let l_contour = l_contour_SKBB;
let l_rockborder = l_rockborder_UIS;
let l_rockedge = l_rockedge_UIS;
let l_flowstone = l_flowstone_UIS;
let l_moonmilk = l_moonmilk_UIS;
let l_section = l_section_SKBB;
let l_survey_cave = l_survey_cave_SKBB;
let l_survey_surface = l_survey_surface_SKBB;
let l_arrow = l_arrow_SKBB;
let l_gradient = l_gradient_UIS;
let l_mapconnection = l_mapconnection_SKBB;
let l_handrail = l_handrail_SKBB;
let l_steps = l_steps_SKBB;
let l_fixedladder = l_fixedladder_SKBB;
let l_ropeladder = l_ropeladder_SKBB;
let l_rope = l_rope_SKBB;
let l_viaferrata = l_viaferrata_SKBB;

let a_water = a_water_UIS;
let a_sump = a_sump_UIS;
let a_sand = a_sand_UIS;
let a_debris = a_debris_SKBB;
let a_blocks = a_blocks_SKBB;
let a_snow = a_snow_SKBB;
let a_ice = a_ice_SKBB;
let a_pebbles = a_pebbles_SKBB;
let a_clay = a_clay_SKBB;
let a_bedrock = a_bedrock_SKBB;
let a_flowstone = a_flowstone_ASF;
let a_moonmilk = a_moonmilk_SKBB;
let a_dimensions = a_dimensions_SKBB;
let a_mudcrack = a_mudcrack_SBE;
let a_pillar = a_pillar_SBE;
let a_pillarwithcurtains = a_pillarwithcurtains_SBE;
let a_stalactite = a_stalactite_SBE;
let a_stalactitestalagmite = a_stalactitestalagmite_SBE;
let a_stalagmite = a_stalagmite_SBE;

let s_northarrow = s_northarrow_SKBB;
let s_scalebar = s_scalebar_SKBB;
let s_hgrid = s_hgrid_SM;
let s_vgrid = s_vgrid_SM;



%%%%% ENDINPUT thTrans %%%%%



nonstopmode;
initsymbol("s_hgrid_SM");
initsymbol("s_northarrow_SKBB");
initsymbol("s_scalebar_SKBB");
initsymbol("s_scalebar_SM");
initsymbol("s_vgrid_SM");
initsymbol("p_airdraught_AUT");
initsymbol("p_airdraught_UIS");
initsymbol("p_airdraught_summer_UIS");
initsymbol("p_airdraught_winter_UIS");
initsymbol("p_altar_SBE");
initsymbol("p_anastomosis_UIS");
initsymbol("p_anchor_SKBB");
initsymbol("p_aragonite_NSS");
initsymbol("p_archeoexcavation_SBE");
initsymbol("p_archeomaterial_UIS");
initsymbol("p_audio_SBE");
initsymbol("p_bat_SBE");
initsymbol("p_bedrock_ASF");
initsymbol("p_blocks_AUT");
initsymbol("p_blocks_UIS");
initsymbol("p_bones_SBE");
initsymbol("p_breakdownchoke_AUT");
initsymbol("p_breakdownchoke_NSS");
initsymbol("p_bridge_SKBB");
initsymbol("p_camp_SKBB");
initsymbol("p_cavepearl_SKBB");
initsymbol("p_clay_AUT");
initsymbol("p_clay_SKBB");
initsymbol("p_claychoke_AUT");
initsymbol("p_claytree_AUT");
initsymbol("p_continuation_UIS");
initsymbol("p_crystal_AUT");
initsymbol("p_crystal_UIS");
initsymbol("p_curtain_UIS");
initsymbol("p_curtains_UIS");
initsymbol("p_danger_SBE");
initsymbol("p_debris_AUT");
initsymbol("p_debris_UIS");
initsymbol("p_dig_UIS");
initsymbol("p_discpillar_UIS");
initsymbol("p_discpillars_UIS");
initsymbol("p_discstalactite_UIS");
initsymbol("p_discstalactites_UIS");
initsymbol("p_discstalagmite_UIS");
initsymbol("p_discstalagmites_UIS");
initsymbol("p_disk_UIS");
initsymbol("p_electriclight_SBE");
initsymbol("p_entrance_AUT");
initsymbol("p_entrance_UIS");
initsymbol("p_exvoto_SBE");
initsymbol("p_fixedladder_SKBB");
initsymbol("p_flowstone_UIS");
initsymbol("p_flowstonechoke_NSS");
initsymbol("p_flute_UIS");
initsymbol("p_gate_SBE");
initsymbol("p_gradient_AUT");
initsymbol("p_gradient_BCRA");
initsymbol("p_gradient_NSS");
initsymbol("p_gradient_SKBB");
initsymbol("p_gradient_UIS");
initsymbol("p_guano_UIS");
initsymbol("p_gypsum_NSS");
initsymbol("p_gypsumflower_NSS");
initsymbol("p_handrail_SKBB");
initsymbol("p_helictite_UIS");
initsymbol("p_helictites_UIS");
initsymbol("p_humanbones_SBE");
initsymbol("p_ice_AUT");
initsymbol("p_ice_UIS");
initsymbol("p_icepillar_AUT");
initsymbol("p_icestalactite_AUT");
initsymbol("p_icestalagmite_AUT");
initsymbol("p_karren_UIS");
initsymbol("p_lowend_NSS");
initsymbol("p_lowend_UIS");
initsymbol("p_masonry_SBE");
initsymbol("p_minus_UIS");
initsymbol("p_moonmilk_UIS");
initsymbol("p_mud_SBE");
initsymbol("p_mudcrack_SBE");
initsymbol("p_nameplate_SBE");
initsymbol("p_narrowend_UIS");
initsymbol("p_noequipment_SKBB");
initsymbol("p_nowheelchair_SBE");
initsymbol("p_paleomaterial_UIS");
initsymbol("p_pebbles_AUT");
initsymbol("p_pebbles_UIS");
initsymbol("p_pendant_SBE");
initsymbol("p_photo_SBE");
initsymbol("p_pillar_AUT");
initsymbol("p_pillar_UIS");
initsymbol("p_pillars_UIS");
initsymbol("p_pillarswithcurtains_UIS");
initsymbol("p_pillarwithcurtains_UIS");
initsymbol("p_plus_UIS");
initsymbol("p_plusminus_UIS");
initsymbol("p_popcorn_UIS");
initsymbol("p_raft_NSS");
initsymbol("p_raftcone_NSS");
initsymbol("p_rimstonedam_ASF");
initsymbol("p_rimstonepool_ASF");
initsymbol("p_root_ASF");
initsymbol("p_rope_SKBB");
initsymbol("p_ropeladder_SKBB");
initsymbol("p_sand_AUT");
initsymbol("p_sand_UIS");
initsymbol("p_scallop_UIS");
initsymbol("p_seedgermination_SBE");
initsymbol("p_sink_AUT");
initsymbol("p_sink_SKBB");
initsymbol("p_snow_SKBB");
initsymbol("p_sodastraw_UIS");
initsymbol("p_spring_AUT");
initsymbol("p_spring_SKBB");
initsymbol("p_stalactite_AUT");
initsymbol("p_stalactite_UIS");
initsymbol("p_stalactites_UIS");
initsymbol("p_stalactitesstalagmites_UIS");
initsymbol("p_stalactitestalagmite_UIS");
initsymbol("p_stalagmite_AUT");
initsymbol("p_stalagmite_UIS");
initsymbol("p_stalagmites_UIS");
initsymbol("p_station_SKBB");
initsymbol("p_station_fixed_ASF");
initsymbol("p_station_fixed_AUT");
initsymbol("p_station_natural_ASF");
initsymbol("p_station_painted_AUT");
initsymbol("p_station_painted_SKBB");
initsymbol("p_station_temporary_ASF");
initsymbol("p_station_temporary_AUT");
initsymbol("p_station_temporary_SKBB");
initsymbol("p_steps_SKBB");
initsymbol("p_traverse_SKBB");
initsymbol("p_treetrunk_SBE");
initsymbol("p_vegetabledebris_ASF");
initsymbol("p_viaferrata_SKBB");
initsymbol("p_volcano_SBE");
initsymbol("p_walkway_SBE");
initsymbol("p_wallcalcite_UIS");
initsymbol("p_water_AUT");
initsymbol("p_water_UIS");
initsymbol("p_waterdrip_SBE");
initsymbol("p_waterflow_intermittent_UIS");
initsymbol("p_waterflow_paleo_UIS");
initsymbol("p_waterflow_permanent_UIS");
initsymbol("p_wheelchair_SBE");
initsymbol("l_abyssentrance_SBE");
initsymbol("l_arrow_SKBB");
initsymbol("l_border_presumed_SKBB");
initsymbol("l_border_temporary_SKBB");
initsymbol("l_border_visible_SKBB");
initsymbol("l_ceilingmeander_AUT");
initsymbol("l_ceilingmeander_NZSS");
initsymbol("l_ceilingmeander_SKBB");
initsymbol("l_ceilingmeander_UIS");
initsymbol("l_ceilingstep_AUT");
initsymbol("l_ceilingstep_NZSS");
initsymbol("l_ceilingstep_SKBB");
initsymbol("l_ceilingstep_UIS");
initsymbol("l_chimney_NZSS");
initsymbol("l_chimney_UIS");
initsymbol("l_contour_AUT");
initsymbol("l_contour_SKBB");
initsymbol("l_contour_UIS");
initsymbol("l_dripline_SBE");
initsymbol("l_fault_SBE");
initsymbol("l_fixedladder_SKBB");
initsymbol("l_floormeander_SKBB");
initsymbol("l_floorstep_AUT");
initsymbol("l_floorstep_UIS");
initsymbol("l_flowstone_AUT");
initsymbol("l_flowstone_UIS");
initsymbol("l_gradient_BCRA");
initsymbol("l_gradient_UIS");
initsymbol("l_handrail_SKBB");
initsymbol("l_joint_SBE");
initsymbol("l_lowceiling_SBE");
initsymbol("l_mapconnection_SKBB");
initsymbol("l_moonmilk_UIS");
initsymbol("l_overhang_AUT");
initsymbol("l_overhang_SKBB");
initsymbol("l_pit_AUT");
initsymbol("l_pit_UIS");
initsymbol("l_pitchimney_SBE");
initsymbol("l_rimstonedam_SBE");
initsymbol("l_rimstonepool_SBE");
initsymbol("l_rockborder_UIS");
initsymbol("l_rockedge_UIS");
initsymbol("l_rope_SKBB");
initsymbol("l_ropeladder_SKBB");
initsymbol("l_section_SKBB");
initsymbol("l_slope_BCRA");
initsymbol("l_slope_SKBB");
initsymbol("l_steps_SKBB");
initsymbol("l_survey_cave_AUT");
initsymbol("l_survey_cave_SKBB");
initsymbol("l_survey_cave_UIS");
initsymbol("l_survey_surface_SKBB");
initsymbol("l_viaferrata_SKBB");
initsymbol("l_walkway_SBE");
initsymbol("l_wall_bedrock_UIS");
initsymbol("l_wall_blocks_AUT");
initsymbol("l_wall_blocks_SKBB");
initsymbol("l_wall_clay_AUT");
initsymbol("l_wall_clay_SKBB");
initsymbol("l_wall_debris_AUT");
initsymbol("l_wall_debris_SKBB");
initsymbol("l_wall_flowstone_AUT");
initsymbol("l_wall_ice_AUT");
initsymbol("l_wall_ice_SKBB");
initsymbol("l_wall_moonmilk_AUT");
initsymbol("l_wall_overlying_AUT");
initsymbol("l_wall_pebbles_AUT");
initsymbol("l_wall_pebbles_SKBB");
initsymbol("l_wall_pit_AUT");
initsymbol("l_wall_presumed_NZSS");
initsymbol("l_wall_presumed_UIS");
initsymbol("l_wall_sand_AUT");
initsymbol("l_wall_sand_SKBB");
initsymbol("l_wall_underlying_AUT");
initsymbol("l_wall_underlying_UIS");
initsymbol("l_wall_unsurveyed_SKBB");
initsymbol("l_waterflow_conjectural_SKBB");
initsymbol("l_waterflow_intermittent_SKBB");
initsymbol("l_waterflow_permanent_UIS");
initsymbol("a_bedrock_SKBB");
initsymbol("a_blocks_AUT");
initsymbol("a_blocks_SKBB");
initsymbol("a_clay_AUT");
initsymbol("a_clay_SKBB");
initsymbol("a_debris_AUT");
initsymbol("a_debris_SKBB");
initsymbol("a_debris_UIS");
initsymbol("a_dimensions_SKBB");
initsymbol("a_flowstone_ASF");
initsymbol("a_flowstone_AUT");
initsymbol("a_ice_AUT");
initsymbol("a_ice_SKBB");
initsymbol("a_moonmilk_SKBB");
initsymbol("a_mudcrack_SBE");
initsymbol("a_pebbles_AUT");
initsymbol("a_pebbles_SKBB");
initsymbol("a_pillar_SBE");
initsymbol("a_pillarwithcurtains_SBE");
initsymbol("a_sand_AUT");
initsymbol("a_sand_UIS");
initsymbol("a_snow_AUT");
initsymbol("a_snow_SKBB");
initsymbol("a_stalactite_SBE");
initsymbol("a_stalactitestalagmite_SBE");
initsymbol("a_stalagmite_SBE");
initsymbol("a_sump_AUT");
initsymbol("a_sump_SKBB");
initsymbol("a_sump_UIS");
initsymbol("a_water_AUT");
initsymbol("a_water_SKBB");
initsymbol("a_water_UIS");

fonts_setup(5.0,10.0,14.0,21.0,28.0);
lang:="en";
ATTR__elevation:=false;

% user defined symbols defaults
let l_u_texture_MY = l_u;
def l_u_texture_MY_legend = l_u_texture_MY(((-.3,0.5) .. (.3,.3) .. (.7,.7) .. (1.3,.5)) inscale) enddef;
% end of user defined symbols

defaultfont:="cmss10";
NorthDir:="true";
def s_northarrow (expr rot) =
begingroup
interim defaultscale:=0.5; % scale your north arrow here
T:=identity scaled defaultscale rotated -rot;
pickup pencircle scaled (0.08cm * defaultscale);
thdraw (-.4cm,-1.4cm)--(0,2.8cm)--(.4cm,-1.4cm)--cycle;
p:=fullcircle scaled 1.6cm;
thclean p; thdraw p;
p:=(0.95cm,0)--(0.65cm,0);
thdraw p; thdraw p xscaled -1;
pickup pencircle scaled (0.12cm * defaultscale);
p:=(0.28cm,0.42cm);
thdraw p--(p yscaled -1)--(p xscaled -1)--(p scaled -1);
endgroup;
enddef;
def s_scalebar (expr l, units, txt) =
begingroup
interim warningcheck:=0;
tmp20:=20 * (l / Scale * cm * units / 100);
tmp40:=40 * (l / Scale * cm * units / 100);
tmp60:=60 * (l / Scale * cm * units / 100);
tmp80:=80 * (l / Scale * cm * units / 100);
tmp100:=100 * (l / Scale * cm * units / 100);
scal10:=10 * l / 100;
scal20:=20 * l / 100;
scal40:=40 * l / 100;
scal60:=60 * l / 100;
scal80:=80 * l / 100;
brht:= 5bp;
lblht:= 8bp;
endgroup;
pickup PenD;
draw (0,0)--(0,brht)--(tmp100,brht)--(tmp100,0)--(0,0);
draw (tmp20,0)--(tmp20,brht);
draw (tmp40,0)--(tmp40,brht);
draw (tmp60,0)--(tmp60,brht);
draw (tmp80,0)--(tmp80,brht);
fill (tmp20,0)--(tmp40,0)--(tmp40,brht)--(tmp20,brht)--cycle;
fill (tmp60,0)--(tmp80,0)--(tmp80,brht)--(tmp60,brht)--cycle;
begingroup
label.top(thTEX(decimal (l) & "\thinspace" & txt),origin+(tmp100,lblht));
label.top(thTEX(decimal (scal80)),origin+(tmp80,lblht));
label.top(thTEX(decimal (scal60)),origin+(tmp60,lblht));
label.top(thTEX(decimal (scal40)),origin+(tmp40,lblht));
label.top(thTEX(decimal (scal20)),origin+(tmp20,lblht));
label.top(thTEX(decimal (0)),origin+(0,lblht));
label.bot(thTEX("PLAN 1 : " & decimal round(Scale*100)),(tmp40+scal10,-2lblht));
endgroup
enddef;
def p_u_gradice_MY (expr P,R,S,A)=
U:=(.2u,.2u);
T:=identity aligned A rotated R scaled S shifted P;
pickup PenD;
thfill (-.12u,.08u)--(0,.12u)--(.12u,.08u)--(0,.3u)--cycle withcolor (0,0.7,0.9);
thfill (-.12u,.08u)--(0,.12u)--(.12u,.08u)--(.12u,-.28u)--(-.12u,-.28u)--cycle withcolor (1,1,1);
thdraw (0,-.28u)--(0,0.15u) withcolor (0,0.7,0.9);
enddef;
def p_debris_MY (expr P,R,S,A)=
U:=(.2u,.2u);
T:=identity aligned A rotated R scaled S shifted P;
pickup PenD;
p:=(0.1u,0)--(0u,0u);
k:= 5*(normaldeviate);
thclean (-0.2u,-0.2u)--(0.2u,-0.2u)--(0.2u,0.2u)--(0.2u,-0.2u)--cycle;
thdraw p rotated (45+k) shifted (-0.15u,-0.15u) withcolor(0.7,0.3,.2);
thdraw p rotated (-40+k) shifted (-0.2u,0.2u) withcolor(0.7,0.3,.2);
thdraw p rotated (10-k) shifted (-0.15u,0.03u) withcolor(0.7,0.3,.2);
thdraw p rotated (-60+k) shifted (0u,0.12u) withcolor(0.7,0.3,.2);
thdraw p rotated (70+k) shifted (0.1u,0.18u) withcolor(0.7,0.3,.2);
thdraw p rotated (-42-k) shifted (0.18u,0.06u) withcolor(0.7,0.3,.2);
thdraw p rotated (32+k) shifted (0.05u,-0.16u) withcolor(0.7,0.3,0.2);
thdraw p rotated (82-k) shifted (0.02u,0.22u) withcolor(0.7,0.3,0.2);
enddef;
def p_waterflow_permanent_MY (expr P,R,S,A)=
U:=(.2u,.2u);
T:=identity aligned A rotated R scaled S shifted P;
pickup PenD;
thdraw (-.07u,.28u)--(.07u,.28u)--(0,0.43u)--cycle;
thfill (-.07u,.28u)--(.07u,.28u)--(0,0.43u)--cycle;
thdraw (-0.04u,0.29u)..(.04u,.2u)..(-0.05u,0.1u)..(.05u,0)..(-0.05u,-0.1u)..(0,-0.2u);
enddef;
def p_station_fixed_MY (expr pos)=
T:=identity shifted pos;
pickup PenD;
pair z;
z:=(0,.7u);
thclean (-.05u,-.05u)..(-.05u,.05u)..(.05u,.05u)..(.05u,-.05u)..cycle;
thfill (-.05u,-.05u)..(-.05u,.05u)..(.05u,.05u)..(.05u,-.05u)..cycle withcolor(0.7,0,0);
enddef;
def p_airdraught_MY (expr P,R,S,A)=
U:=(.2u,.2u);
T:=identity aligned A rotated R scaled S shifted P;
pickup PenD;
thfill (-.12u,.08u)--(0,.12u)--(.12u,.08u)--(0,.3u)--cycle;
thdraw (-.1u,-.35u)--(0,-.28u)--(.1u,-0.35u);
thdraw (-.1u,-.25u)--(0,-.18u)--(.1u,-.25u);
thdraw (0,-.28u)--(0,0.15u);
enddef;
def p_u_grass_MY (expr P,R,S,A)=
U:=(.2u,.2u);
T:=identity aligned A rotated R scaled S shifted P;
pickup PenC;
thdraw (0.15u,0.1u)--(0,-0.2u)--(0,0.25u) withcolor (0.3,0.7,0.25);
thdraw (0.13u,-0.2u)--(0,-0.2u)--(-0.17u,0.18u) withcolor (0.3,0.7,0.25);
enddef;
def p_gradient_MY (expr P,R,S,A)=
U:=(.2u,.2u);
T:=identity aligned A rotated R scaled S shifted P;
pickup PenD;
thfill (-.12u,.08u)--(0,.12u)--(.12u,.08u)--(0,.3u)--cycle;
thfill (-.12u,.08u)--(0,.12u)--(.12u,.08u)--(.12u,-.28u)--(-.12u,-.28u)--cycle withcolor(1,1,1);
thdraw (0,-.28u)--(0,0.15u);
enddef;
def p_pillar_MY (expr P,R,S,A)=
U:=(.2u,.2u);
T:=identity aligned A rotated R scaled S shifted P;
pickup PenC;
thdraw (-.2u,-.2u)..(-.2u,.2u)..(.2u,.2u)..(.2u,-.2u)..cycle withcolor(1,0.5,0.1);
thfill (-.1u,-.1u)..(-.1u,.1u)..(.1u,.1u)..(.1u,-.1u)..cycle withcolor(1,0.5,0.1);
enddef;
def p_stalagmite_MY (expr P,R,S,A)=
U:=(.2u,.2u);
T:=identity aligned A rotated R scaled S shifted P;
pickup PenC;
thfill (-.1u,-.1u)..(-.1u,.1u)..(.1u,.1u)..(.1u,-.1u)..cycle withcolor(1,0.5,0.1);
enddef;
def p_stalactite_MY (expr P,R,S,A)=
U:=(.2u,.2u);
T:=identity aligned A rotated R scaled S shifted P;
pickup PenC;
thdraw (-.1u,-.1u)..(-.1u,.1u)..(.1u,.1u)..(.1u,-.1u)..cycle withcolor(1,0.5,0.1);
enddef;
def p_u_sampled_MY (expr P,R,S,A)=
U:=(.2u,.2u);
T:=identity aligned A rotated R scaled S shifted P;
thdraw (-.2u,-.2u)..(-.2u,.2u)..(.2u,.2u)..(.2u,-.2u)..cycle withcolor(1,0.1,0.6);
thfill (-.1u,-.1u)..(-.1u,.1u)..(.1u,.1u)..(.1u,-.1u)..cycle withcolor(1,0.1,0.6);
enddef;
def p_u_logger_MY (expr P,R,S,A)=
U:=(.2u,.2u);
T:=identity aligned A rotated R scaled S shifted P;
thdraw (-.3u,-.3u)--(-.3u,.3u)--(.3u,.3u)..(.3u,-.3u)--cycle;
thfill (-.2u,-.2u)--(-.2u,.2u)--(.2u,.2u)..(.2u,-.2u)--cycle;
enddef;
def p_u_waterdrip_MY (expr P,R,S,A)=
U:=(.2u,.2u);
T:=identity aligned A rotated R scaled S shifted P;
pickup PenD;
thdraw (0u,0u)--(0,.15u) withcolor(0,0.1,0.7);
thdraw (0,.3u)--(0,.45u) withcolor(0,0.1,0.7);
thdraw (0,-.15u)--(0,-.3u) withcolor(0,0.1,0.7);
thfill (-.18u,-.15u)--(0,-.45u)--(.18u,-.15u)--(0,-.22u)--cycle withcolor(0,0.1,0.7);
enddef;
def l_u_woody_MY (expr P)=
T:= identity;
thclean P;
thdraw P withpen PenD withcolor (0.3,0.1,0.05);
thfill P withpen PenD withcolor (0.4,0.15,0.075);
enddef;
def l_u_fault_MY (expr P)=
T:=identity;
pickup PenC;
thdraw P withcolor (0.5,0.5,0.5) dashed evenly scaled (2*optical_zoom);
enddef;
def l_u_overlay_MY (expr P)=
T:=identity;
pickup PenA;
thdraw P withcolor (0.95,0.75,0.5);
enddef;
def l_u_underlay_MY (expr Path)=
T:=identity;
pickup PenA;
thdraw Path withcolor(0.95,0.75,0.5) dashed evenly scaled (2*optical_zoom);
enddef;
def l_u_mine_MY (expr Path)=
T:=identity;
pickup PenA;
thdraw Path withcolor(0.82,0.55,0.82);
enddef;
def l_u_dripline_MY (expr Path)=
T:=identity;
pickup PenC;
thdraw Path withcolor (0.25,0.25,0.25) dashed evenly scaled (1*optical_zoom);
enddef;
def l_wall_blocks_MY (expr P)=
T:=identity;
cas := 0;
dlzka := arclength P;
if dlzka > 0:
mojkrok:=adjust_step(dlzka, 0.5u);
pickup PenC;
forever:
t1 := arctime (cas + mojkrok*1/10) of P;
t2 := arctime (cas + mojkrok*9/10) of P;
q := ((point t1 of P) + .2u * unitvector(thdir(P,t1) rotated -125)) --
(subpath (t1,t2) of P) --
((point t2 of P) + .2u * unitvector(thdir(P,t2) rotated -75));
thdraw q randomized (u/12) withcolor(0.3,0.3,0.3);
cas := cas + mojkrok;
exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
endfor;
fi;
enddef;
def l_wall_flowstone_MY (expr P) =
T:=identity;
cas := 0;
dlzka := arclength P;
mojkrok:=adjust_step(dlzka, .75u);
pickup PenC;
p := (-.25u,-.05u)--(-.175u,.05u)--(-.1u,-.05u);
q := (-.025u,-.05u)--(.05u,.05u)--(0.125u,-.05u);
forever:
t := arctime (cas + mojkrok/2) of P;
thdraw p shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90)) withcolor(0.85,0.45,0.1);
thdraw q shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90)) withcolor(0.85,0.45,0.1);
cas := cas + mojkrok;
exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
endfor;
pickup PenA;
thdraw P withcolor(1,0.5,0.1);
enddef;
def l_wall_ice_MY (expr P) =
T:=identity;
cas := 0;
dlzka := arclength P;
mojkrok:=adjust_step(dlzka, .9u);
pickup PenC;
p := (0,-0.15u)--(0,0.15u);
forever:
t1 := arctime (cas + mojkrok/6) of P;
t2 := arctime (cas + mojkrok*2/6) of P;
t3 := arctime (cas + mojkrok*3/6) of P;
t5 := arctime (cas + mojkrok*5/6) of P;
q := subpath(t1,t3) of P;
p := (point t5 of P + .45u * unitvector(thdir(P,t5) rotated -90))--(point t5 of P + .2u * unitvector(thdir(P,t5) rotated -90));
thdraw q shifted ( .3u * unitvector(thdir(P,t2) rotated -90)) withcolor(0,0.7,0.9);
thdraw p  withcolor(0,0.7,0.9);
cas := cas + mojkrok;
exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
endfor;
pickup PenA;
thdraw P withcolor(0,0.7,0.9);
enddef;
def l_u_texture_MY (expr P)=
T:=identity;
thdraw P withpen PenD withcolor (0.3,0.3,0.3);
enddef;
def l_contour_MY (expr P)(text txt) =
T:=identity;
pickup PenC;
thdraw P;
enddef;
def l_survey_cave_MY (expr P) =
T:=identity;
draw P withpen PenD withcolor (0.7,0,0);
enddef;
def l_rockborder_MY (expr P) =
T:=identity;
pickup PenC;
if cycle P: thclean P fi;
thdraw P withcolor (0.3,0.3,0.3);
enddef;
def l_u_wall_flowstone_MY (expr P)=
T:=identity;
cas := 0;
dlzka := arclength P;
if dlzka > 0:
mojkrok:=adjust_step(dlzka, 0.5u);
pickup PenC;
forever:
t1 := arctime (cas + mojkrok*2.5/10) of P;
t1b := arctime (cas + mojkrok*4/10) of P;
t2 := arctime (cas + mojkrok*7.5/10) of P;
t2b := arctime (cas + mojkrok*6/10) of P;
t2a :=arctime (cas +mojkrok*7.49/10) of P;
q := ((point t1 of P) + 0.05u * unitvector(thdir(P,t1) rotated -115)) ..
((point t1b of P) - .01u * unitvector(thdir(P,t1b) rotated -90)) ..
((point t2b of P) - .01u * unitvector(thdir(P,t1b) rotated -90)) ..
((point t2 of P) + .05u * unitvector(thdir(P,t2) rotated -65))--
((point t2a of P) + .05u * unitvector(thdir(P,t2a) rotated -65)) ..
((point t2b of P) + .01u * unitvector(thdir(P,t1b) rotated -90)) ..
((point t1b of P) + .01u * unitvector(thdir(P,t1b) rotated -90)) ..
((point t1 of P) + .05u * unitvector(thdir(P,t1) rotated -115));
thdraw q withcolor(0.85,0.45,0.1);
cas := cas + mojkrok;
exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
endfor;
fi;
enddef;
def a_water_MY (expr p) =
T:=identity;
thfill p withcolor (0.1,0.1,0.25);
enddef;
def l_u_wallstep_MY (expr P) =
T:=identity;
laenge:= arclength P;
symsize:=adjust_step(laenge,0.25u);
ministep:=symsize/5;
cur:=0;
pickup PenC;
forever:
t0 := arctime (cur) of P;
t1 := arctime (cur+ministep) of P;
t2 := arctime (cur+2*ministep) of P;
t3a := arctime (cur+3*ministep) of P;
t4 := arctime (cur+4*ministep) of P;
t5 := arctime (cur+5*ministep) of P;
thclean (subpath (t5,t0) of P) -- ((point t0 of P) + symsize/2 * unitvector(thdir(P,t0) rotated 90)) ..
((point t1 of P) + symsize/2 * unitvector(thdir(P,t1) rotated 90)) ..
((point t2 of P) + symsize/2 * unitvector(thdir(P,t2) rotated 90)) ..
((point t3a of P) + symsize/2 * unitvector(thdir(P,t3a) rotated 90)) ..
((point t4 of P) + symsize/2 * unitvector(thdir(P,t4) rotated 90)) ..
((point t5 of P) + symsize/2 * unitvector(thdir(P,t5) rotated 90))--cycle;
thdraw ((point t0 of P) + symsize/2 * unitvector(thdir(P,t0) rotated 90)) ..
((point t1 of P) + symsize/2 * unitvector(thdir(P,t1) rotated 90)) ..
((point t2 of P) + symsize/2 * unitvector(thdir(P,t2) rotated 90)) ..
((point t3a of P) + symsize/2 * unitvector(thdir(P,t3a) rotated 90)) ..
((point t4 of P) + symsize/2 * unitvector(thdir(P,t4) rotated 90)) ..
((point t5 of P) + symsize/2 * unitvector(thdir(P,t5) rotated 90));
thdraw ((point t3a of P) + symsize/2 * unitvector(thdir(P,t3a) rotated 90)) --
((point t3a of P) + 4/3*symsize * unitvector(thdir(P,t3a) rotated 90)) withpen PenC;
cur := cur + symsize;
exitif cur > laenge - (1*symsize/3); % for rounding errors
endfor;
pickup PenA;
thdraw P;
enddef;
def l_u_icestep_MY (expr P) =
T:=identity;
laenge:= arclength P;
symsize:=adjust_step(laenge,0.25u);
ministep:=symsize/5;
cur:=0;
pickup PenC;
forever:
t0 := arctime (cur) of P;
t1 := arctime (cur+ministep) of P;
t2 := arctime (cur+2*ministep) of P;
t3a := arctime (cur+3*ministep) of P;
t4 := arctime (cur+4*ministep) of P;
t5 := arctime (cur+5*ministep) of P;
thclean (subpath (t5,t0) of P) -- ((point t0 of P) + symsize/2 * unitvector(thdir(P,t0) rotated 90)) ..
((point t1 of P) + symsize/2 * unitvector(thdir(P,t1) rotated 90)) ..
((point t2 of P) + symsize/2 * unitvector(thdir(P,t2) rotated 90)) ..
((point t3a of P) + symsize/2 * unitvector(thdir(P,t3a) rotated 90)) ..
((point t4 of P) + symsize/2 * unitvector(thdir(P,t4) rotated 90)) ..
((point t5 of P) + symsize/2 * unitvector(thdir(P,t5) rotated 90))--cycle;
thdraw P withcolor (0, 0.7,0.9);
thdraw (point t3a of P)  --
((point t3a of P) + 2/3*symsize * unitvector(thdir(P,t3a) rotated 90)) withpen PenC withcolor (0, 0.7,0.9);;
cur := cur + symsize;
exitif cur > laenge - (1*symsize/3); % for rounding errors
endfor;
enddef;
def l_u_icepit_MY (expr P) =
T:=identity;
laenge:= arclength P;
symsize:=adjust_step(laenge,0.5u);
triangle_width:=symsize/2;
cur:=(symsize-triangle_width)/2;
pickup PenC;
forever:
t1 := arctime (cur) of P;
t  := arctime (cur + triangle_width/2) of P;
t2 := arctime (cur + triangle_width) of P;
if ATTR__height >= 10:
thfill (subpath (t1,t2) of P) --
((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) --
cycle;
else:
thclean (subpath (t1,t2) of P) --
((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) --
cycle;
thfill (point t2 of P) --((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) --
(point t1 of P)--cycle withcolor (0, 0.7,0.9);
fi;
cur := cur + symsize;
exitif cur > laenge - (1*symsize/3); % for rounding errors
t1:=arctime (cur) of P;
endfor;
thdraw P withcolor (0, 0.7,0.9);
enddef;
beginpattern(pattern_ice_MY);
pickup PenC;
p:=(-.15u,0)--(.15u,0);
draw p shifted(0.15,0.25u);
draw p rotated -90 shifted (.3u,0.2u);
patternxstep(0.6u);
patternystep(0.6u);
patterncolor(0,0.7,0.9);
endpattern;
def a_ice_MY (expr Path) =
T:=identity;
thclean Path;
thfill Path withpattern pattern_ice_MY;
enddef;
def a_snow_MY (expr P) =
T:=identity;
pickup PenC;
path q; q = bbox P;
picture tmp_pic, tmp_sn;
pair z;
tmp_sn := image(
pickup PenD;
p := origin--(0,.1*u);
draw p; draw p rotated (60); draw p rotated (120);
draw p rotated (180); draw p rotated (240); draw p rotated (300);
);
tmp_pic := image(
for i = xpart llcorner q step 0.5u until xpart urcorner q:
for j = ypart llcorner q step 0.5u until ypart urcorner q:
z:=((i,j) randomized 0.25u);
if xpart (P intersectiontimes ((bbox tmp_sn) shifted z)) < 0:
draw tmp_sn shifted z withcolor(0,0.7,0.9);
fi;
endfor;
endfor;
);
clip tmp_pic to P;
drawoptions();
draw tmp_pic;
enddef;
beginpattern(pattern_clay_MY);
pickup PenD;
p:= (-.008u,0)--(.008u,0);
draw p;
draw p rotated 25 shifted(.1u,0.1u);
patternxstep(0.2u);
patternystep(0.2u);
patterncolor(0.65,0.55,0.1);
endpattern;
def a_clay_MY (expr Path) =
T:=identity;
thclean Path;
thfill Path withpattern pattern_clay_MY;
enddef;
def a_thing_MY (expr p) =
T:=identity;
thclean p;
pickup PenD;
path q; q = bbox p;
picture tmp_pic, tmp_ice;
pair z;
tmp_ice := image (
draw (-.005u,0)--(.005u,0);
);
tmp_pic := image(
for i = xpart llcorner q step .1u until xpart urcorner q:
for j = ypart llcorner q step .1u until ypart urcorner q:
z := ((i,j) randomized 0.02u);
if xpart (p intersectiontimes ((bbox tmp_ice) shifted z)) < 0:
draw tmp_ice shifted z;
fi;
endfor;
endfor;
);
clip tmp_pic to p;
drawoptions();
draw tmp_pic;
enddef;
def a_sand_MY (expr p) =
T:=identity;
thclean p;
pickup PenB;
thfill p withcolor(0.85,0.8,0.5);
path q; q = bbox p;
picture tmp_pic, tmp_ice;
pair z;
tmp_ice := image (
draw (-.005u,0)--(.007u,0);
);
tmp_pic := image(
for i = xpart llcorner q step .35u until xpart urcorner q:
for j = ypart llcorner q step .35u until ypart urcorner q:
z := ((i,j) randomized 0.2u);
if xpart (p intersectiontimes ((bbox tmp_ice) shifted z)) < 0:
draw tmp_ice shifted z;
fi;
endfor;
endfor;
);
clip tmp_pic to p;
drawoptions();
draw tmp_pic;
enddef;
def a_blocks_MY (expr p) =
T:=identity;
pickup PenC;
path q, qq; q = bbox p;
picture tmp_pic;
uu := max(u, (xpart urcorner q - xpart llcorner q)/100, (ypart urcorner q - ypart llcorner q)/100);
tmp_pic := image(
for i = xpart llcorner q step 1uu until xpart urcorner q:
for j = ypart llcorner q step 1uu until ypart urcorner q:
k := (7+normaldeviate)/8;
qq := punked (((-.51uu,.21uu)--(-.51uu,-.21uu)--(0,-.36uu)--(.51uu,-.24uu)--(.45uu,.18uu)--(0,.39uu)--cycle)
randomized (uu/5))
rotated uniformdeviate(360)
scaled k
shifted ((i,j) randomized 0.55uu);
if xpart (p intersectiontimes qq) < 0:
thclean qq;
thdraw qq;
fi;
endfor;
endfor;
);
clip tmp_pic to p;
drawoptions();
draw tmp_pic;
enddef;
def a_u_smallblocks_MY (expr p) =
T:=identity;
pickup PenD;
save S,sc;
string S;
numeric sc;
if known ATTR_scale:
sc :=scantokens(ATTR_scale);
else: sc:=1;
fi;
%if S='xs' : sc:=0.5;
%elseif S='s' : sc:=0.7;
%elseif S=''l' : sc:=1.4;
%elseif S='xl' : sc:=2
%else: sc:=1;
%fi;
path q, qq; q = bbox p;
picture tmp_pic;
uu := max(u, (xpart urcorner q - xpart llcorner q)/100, (ypart urcorner q - ypart llcorner q)/100);
tmp_pic := image(
for i = xpart llcorner q step 0.4uu*sc until xpart urcorner q:
for j = ypart llcorner q step 0.4uu*sc until ypart urcorner q:
k := (4+normaldeviate)/5;
qq := punked (((-.17uu*sc,.07uu*sc)--(-.17uu*sc,-.07uu*sc)--(0,-.12uu*sc)--(.17uu*sc,-.08uu*sc)--(.15uu*sc,.06uu*sc)--(0,.13uu*sc)--cycle)
randomized (uu/9))
rotated uniformdeviate(360)
scaled k
shifted ((i,j) randomized 0.25uu);
if xpart (p intersectiontimes qq) < 0:
thclean qq;
thdraw qq withcolor(0.3,0.3,0.3);
fi;
endfor;
endfor;
);
clip tmp_pic to p;
drawoptions();
draw tmp_pic;
enddef;
def a_pebbles_MY (expr p) =
T:=identity;
thclean p;
pickup PenD;
path q; q = bbox p;
picture tmp_pic;
picture tmp_pebblea;
picture tmp_pebbleb;
pair z;
pair za;
tmp_pebblea := image (
draw (((-.12u,0)..(.05u,0)..(.007u,0.003u)..(-0.004u,0.005u)--cycle) scaled 0.035u) withcolor(0.5,0.5,0.5);
fill (((-.12u,0)..(.05u,0)..(.007u,0.003u)..(-0.004u,0.005u)--cycle) scaled 0.035u) withcolor(0.95,0.95,0.95);
);
tmp_pebbleb := image (
draw (((((-.12u,0)..(.05u,0)..(.007u,0.003u)..(-0.004u,0.005u)--cycle)rotated 35)  scaled 0.025u) shifted (0.2u,0.2u)) withcolor(0.5,0.5,0.5);
fill (((((-.12u,0)..(.05u,0)..(.007u,0.003u)..(-0.004u,0.005u)--cycle)rotated 35) scaled 0.025u) shifted (0.2u,0.2u)) withcolor(0.95,0.95,0.95);
);
tmp_pic := image(
for i = xpart llcorner q step .4u until xpart urcorner q:
for j = ypart llcorner q step .4u until ypart urcorner q:
z := ((i,j) randomized 0.3u);
za :=((i,j) randomized 0.4u) ;
if xpart (p intersectiontimes ((bbox tmp_pebblea) shifted z)) < 0:
draw tmp_pebblea shifted z;
draw tmp_pebbleb shifted z;
fi;
endfor;
endfor;
);
clip tmp_pic to p;
drawoptions();
draw tmp_pic;
enddef;
initsymbol("p_waterflow_permanent_MY");
initsymbol("p_pillar_MY");
initsymbol("p_stalagmite_MY");
initsymbol("p_stalactite_MY");
initsymbol("p_airdraught_MY");
initsymbol("p_gradient_MY");
initsymbol("p_debris_MY");
initsymbol("p_u_logger_MY");
initsymbol("p_u_waterdrip_MY");
initsymbol("p_u_sampled_MY");
initsymbol("p_u_grass_MY");
initsymbol("p_u_gradice_MY");
initsymbol("l_wall_blocks_MY");
initsymbol("l_wall_ice_MY");
initsymbol("l_wall_flowstone_MY");
initsymbol("l_u_overlay_MY");
initsymbol("l_u_mine_MY");
initsymbol("l_u_underlay_MY");
initsymbol("l_u_fault_MY");
initsymbol("l_u_icepit_MY");
initsymbol("l_u_wallstep_MY");
initsymbol("l_u_woody_MY");
initsymbol("l_u_icestep_MY");
initsymbol("l_rockborder_MY");
initsymbol("l_survey_cave_MY");
initsymbol("l_pit_MY");
initsymbol("l_contour_MY");
initsymbol("l_u_dripline_MY");
initsymbol("p_station_fixed_MY");
initsymbol("l_u_texture_MY");
initsymbol("l_u_wall_flowstone_MY");
initsymbol("a_snow_MY");
initsymbol("a_ice_MY");
initsymbol("a_water_MY");
initsymbol("a_clay_MY");
initsymbol("a_sand_MY");
initsymbol("a_pebbles_MY");
initsymbol("a_blocks_MY");
initsymbol("a_u_smallblocks_MY");
mapsymbol("p_station_fixed","AUT",true);
mapsymbol("p_station_natural","AUT",true);
mapsymbol("p_station_painted","AUT",true);
mapsymbol("p_station_temporary","AUT",true);
mapsymbol("l_survey_cave","MY",true);
mapsymbol("l_survey_surface","MY",true);
mapsymbol("p_station_fixed","MY",true);
mapsymbol("p_station_natural","MY",true);
mapsymbol("p_station_painted","MY",true);
mapsymbol("p_station_temporary","MY",true);
mapsymbol("a_ice","MY",true);
mapsymbol("a_snow","MY",true);
mapsymbol("p_stalagmite","MY",true);
mapsymbol("p_stalactite","MY",true);
mapsymbol("p_pillar","MY",true);
mapsymbol("l_rockborder","MY",true);
mapsymbol("a_clay","MY",true);
mapsymbol("a_sand","MY",true);
mapsymbol("a_pebbles","MY",true);
mapsymbol("p_gradient","MY",true);
mapsymbol("l_contour","MY",true);
mapsymbol("l_pit","AUT",true);
mapsymbol("l_wall_bedrock","MY",true);
mapsymbol("l_wall_blocks","MY",true);
mapsymbol("l_wall_clay","MY",true);
mapsymbol("l_wall_debris","MY",true);
mapsymbol("l_wall_ice","MY",true);
mapsymbol("l_wall_pebbles","MY",true);
mapsymbol("l_wall_presumed","MY",true);
mapsymbol("l_wall_sand","MY",true);
mapsymbol("l_wall_underlying","MY",true);
mapsymbol("l_wall_unsurveyed","MY",true);
mapsymbol("l_wall_pit","MY",true);
mapsymbol("l_wall_overlying","MY",true);
mapsymbol("l_wall_moonmilk","MY",true);
mapsymbol("l_wall_flowstone","MY",true);
mapsymbol("p_breakdownchoke","AUT",true);
mapsymbol("p_airdraught","MY",true);
mapsymbol("p_airdraught_summer","MY",true);
mapsymbol("p_airdraught_winter","MY",true);
mapsymbol("p_station_fixed","MY",true);
mapsymbol("p_debris","MY",true);
mapsymbol("a_blocks","MY",true);
transparency:=true;
background:=(1.00000,1.00000,1.00000);
def_transparent_rgb(tr_bg, 1.00000, 1.00000, 1.00000);
current_scrap := "marco_polo_schacht-1p@marco_polo_schacht.gamswandkar";
ATTR__scrap := "marco_polo_schacht-1p";
beginfig(1);
ATTR__survey := "marco_polo_schacht.gamswandkar";
ATTR__height := -1;
drawoptions();
l_floorstep(((-4.09,-22.75)
 .. controls (-4.09,-22.75) and (-5.16,-25.94) .. (-5.54,-26.41)
 .. controls (-5.93,-26.88) and (-8.15,-29.15) .. (-8.64,-29.97)
 .. controls (-9.12,-30.78) and (-9.34,-31.82) .. (-9.38,-32.45)
 .. controls (-9.43,-33.08) and (-8.62,-36.87) .. (-8.31,-37.52)
 .. controls (-8.00,-38.18) and (-7.51,-40.12) .. (-7.51,-40.12)
));
ATTR__height := -1;
drawoptions();
l_floorstep(((7.31,-35.57)
 -- (9.96,-32.31)
 .. controls (9.96,-32.31) and (11.59,-31.31) .. (11.36,-30.51)
 .. controls (11.14,-29.72) and (7.51,-26.11) .. (7.51,-26.11)
 -- (3.70,-24.97)
));
ATTR__height := -1;
drawoptions();
l_u_texture_MY(((15.92,-15.78)
 .. controls (15.92,-15.78) and (17.75,-14.02) .. (18.04,-12.83)
 .. controls (18.32,-11.65) and (17.01,-7.65) .. (16.94,-7.24)
 .. controls (16.87,-6.84) and (12.66,-1.42) .. (11.62,-0.54)
 .. controls (10.58,0.34) and (3.62,4.96) .. (2.87,5.61)
 .. controls (2.11,6.27) and (-1.74,12.36) .. (-2.59,14.32)
 .. controls (-3.45,16.29) and (-12.81,23.68) .. (-12.81,23.68)
 .. controls (-12.81,23.68) and (-23.08,25.64) .. (-24.71,25.26)
 .. controls (-26.34,24.88) and (-29.58,24.33) .. (-31.78,24.39)
 .. controls (-33.98,24.46) and (-41.43,25.12) .. (-42.14,26.37)
 .. controls (-42.84,27.62) and (-46.29,37.78) .. (-45.73,38.54)
 .. controls (-45.17,39.30) and (-43.14,45.14) .. (-43.14,45.14)
));
ATTR__height := -1;
drawoptions();
l_contour(((-3.97,16.02)
 .. controls (-2.56,16.87) and (6.27,23.98) .. (6.27,23.98)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((7.32,15.74)
 .. controls (7.32,15.74) and (1.84,10.69) .. (0.73,8.47)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((11.74,7.86)
 .. controls (11.74,7.86) and (7.59,5.21) .. (6.81,2.72)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((17.37,-1.31)
 .. controls (17.37,-1.31) and (14.90,-2.28) .. (14.06,-3.52)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((28.30,-10.88)
 .. controls (28.30,-10.88) and (22.12,-10.43) .. (18.00,-11.88)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((24.16,-29.01)
 .. controls (24.16,-29.01) and (17.34,-21.07) .. (12.73,-18.21)
),-1);
ATTR__height := -1;
drawoptions();
l_u_texture_MY(((-1.62,-51.25)
 .. controls (-1.62,-51.25) and (4.85,-44.82) .. (5.09,-44.34)
 .. controls (5.32,-43.86) and (6.03,-38.31) .. (6.30,-37.43)
 .. controls (6.56,-36.55) and (7.86,-35.25) .. (7.86,-35.25)
 -- (15.19,-30.92)
 .. controls (15.19,-30.92) and (18.34,-30.27) .. (19.05,-30.22)
 .. controls (19.76,-30.17) and (23.96,-28.89) .. (23.96,-28.89)
 .. controls (23.96,-28.89) and (28.39,-30.13) .. (29.71,-33.94)
 .. controls (31.03,-37.74) and (44.02,-47.72) .. (44.02,-47.72)
 -- (46.15,-51.48)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-19.52,-29.79)
 -- (-22.64,-30.50)
 .. controls (-22.64,-30.50) and (-25.81,-30.61) .. (-26.08,-30.94)
 .. controls (-26.36,-31.26) and (-26.96,-31.82) .. (-27.17,-32.05)
 .. controls (-27.39,-32.29) and (-28.24,-32.87) .. (-28.56,-33.10)
 .. controls (-28.88,-33.33) and (-29.64,-35.42) .. (-29.58,-35.88)
 .. controls (-29.51,-36.34) and (-29.14,-38.63) .. (-29.14,-38.63)
 .. controls (-29.14,-38.63) and (-22.56,-35.93) .. (-22.18,-35.66)
 .. controls (-21.81,-35.38) and (-18.80,-33.46) .. (-18.80,-33.46)
 .. controls (-18.80,-33.46) and (-18.43,-32.59) .. (-18.54,-32.03)
 .. controls (-18.65,-31.47) and (-19.52,-29.79) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-20.53,45.15)
 -- (-26.11,45.47)
 .. controls (-26.11,45.47) and (-28.33,42.54) .. (-28.56,42.16)
 .. controls (-28.79,41.77) and (-30.49,37.70) .. (-30.49,37.70)
 .. controls (-30.49,37.70) and (-28.96,35.39) .. (-28.47,35.35)
 .. controls (-27.97,35.31) and (-21.01,35.99) .. (-21.01,35.99)
 .. controls (-21.01,35.99) and (-20.52,37.26) .. (-20.25,38.24)
 .. controls (-19.98,39.22) and (-19.37,42.07) .. (-19.37,42.07)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-6.24,35.79)
 .. controls (-6.24,35.79) and (-9.77,32.46) .. (-10.30,32.00)
 .. controls (-10.83,31.54) and (-12.57,29.67) .. (-12.57,29.67)
 .. controls (-12.57,29.67) and (-10.13,24.78) .. (-9.86,24.36)
 .. controls (-9.59,23.94) and (-8.64,23.27) .. (-7.11,23.66)
 .. controls (-5.58,24.05) and (-4.48,25.37) .. (-3.96,25.63)
 .. controls (-3.44,25.89) and (-2.63,27.43) .. (-2.10,29.19)
 .. controls (-1.58,30.95) and (-1.19,32.32) .. (-1.19,32.32)
 -- cycle
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-5.20,45.02) -- (-25.26,40.85)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-25.26,40.85) -- (12.45,-0.89)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-25.26,40.85) -- (-5.20,45.02)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((12.45,-0.89) -- (29.60,-25.69)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((12.45,-0.89) -- (-25.26,40.85)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((29.60,-25.69) -- (3.93,-24.99)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((29.60,-25.69) -- (12.45,-0.89)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((3.93,-24.99) -- (-9.51,-26.92)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((3.93,-24.99) -- (-3.78,-38.59)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((3.93,-24.99) -- (29.60,-25.69)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-3.78,-38.59) -- (3.93,-24.99)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-9.51,-26.92) -- (-39.60,-32.96)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-9.51,-26.92) -- (3.93,-24.99)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-39.60,-32.96) -- (-9.51,-26.92)));
endfig;
beginfig(2);
draw_upscrap(1)(1,((13.92,53.18)
 .. controls (13.92,53.18) and (5.02,51.81) .. (3.79,51.46)
 .. controls (2.56,51.11) and (0.85,51.05) .. (0.04,51.18)
 .. controls (-0.77,51.30) and (-3.05,52.17) .. (-3.15,52.49)
 .. controls (-3.25,52.81) and (-6.35,52.80) .. (-6.67,52.76)
 .. controls (-6.99,52.72) and (-12.02,50.63) .. (-12.73,50.37)
 .. controls (-13.45,50.10) and (-15.30,49.93) .. (-16.52,49.70)
 .. controls (-17.74,49.48) and (-19.19,47.82) .. (-19.19,47.82)
 .. controls (-19.19,47.82) and (-23.00,46.78) .. (-24.02,46.73)
 .. controls (-25.03,46.68) and (-27.33,47.36) .. (-27.89,47.40)
 .. controls (-28.46,47.44) and (-31.57,48.94) .. (-32.76,49.15)
 .. controls (-33.95,49.37) and (-34.01,49.37) .. (-34.01,49.37)
 .. controls (-34.01,49.37) and (-37.74,47.75) .. (-38.21,47.34)
 .. controls (-38.69,46.94) and (-42.95,44.98) .. (-43.29,44.69)
 .. controls (-43.62,44.39) and (-45.33,41.04) .. (-46.08,40.27)
 .. controls (-46.84,39.51) and (-49.52,35.85) .. (-50.06,35.38)
 .. controls (-50.60,34.91) and (-51.31,34.78) .. (-51.59,34.29)
 .. controls (-51.88,33.81) and (-52.27,32.00) .. (-52.31,31.50)
 .. controls (-52.35,31.00) and (-48.48,24.38) .. (-47.39,23.60)
 .. controls (-46.31,22.82) and (-38.44,20.53) .. (-37.91,20.04)
 .. controls (-37.38,19.56) and (-35.77,19.00) .. (-34.93,18.36)
 .. controls (-34.09,17.73) and (-31.76,16.79) .. (-31.76,16.79)
 .. controls (-31.76,16.79) and (-26.06,20.10) .. (-25.57,20.63)
 .. controls (-25.09,21.17) and (-23.18,21.34) .. (-22.19,21.84)
 .. controls (-21.20,22.33) and (-15.94,23.27) .. (-15.28,22.78)
 .. controls (-14.61,22.29) and (-11.69,18.97) .. (-11.53,18.64)
 .. controls (-11.36,18.31) and (-6.18,14.76) .. (-5.90,14.17)
 .. controls (-5.63,13.58) and (-2.68,9.82) .. (-2.39,9.42)
 .. controls (-2.10,9.02) and (1.04,4.48) .. (1.27,4.15)
 .. controls (1.50,3.81) and (8.03,-4.65) .. (8.03,-4.65)
 .. controls (8.03,-4.65) and (10.93,-6.64) .. (11.23,-6.92)
 .. controls (11.52,-7.20) and (14.67,-11.80) .. (14.95,-12.33)
 .. controls (15.23,-12.86) and (15.84,-14.05) .. (15.84,-14.93)
 .. controls (15.84,-15.82) and (16.18,-15.59) .. (15.55,-16.30)
 .. controls (14.93,-17.00) and (14.00,-17.62) .. (13.78,-17.92)
 .. controls (13.57,-18.21) and (9.57,-18.15) .. (9.57,-18.15)
 .. controls (9.57,-18.15) and (8.21,-17.67) .. (7.92,-18.09)
 .. controls (7.64,-18.52) and (7.70,-18.52) .. (7.65,-19.21)
 .. controls (7.60,-19.91) and (8.36,-21.68) .. (8.21,-22.11)
 .. controls (8.05,-22.54) and (7.69,-23.03) .. (7.29,-23.31)
 .. controls (6.89,-23.60) and (6.04,-23.92) .. (5.46,-24.06)
 .. controls (4.88,-24.21) and (2.81,-22.85) .. (2.45,-22.57)
 .. controls (2.09,-22.30) and (0.21,-20.26) .. (0.21,-20.26)
 .. controls (0.21,-20.26) and (-0.77,-19.81) .. (-1.23,-19.97)
 .. controls (-1.69,-20.13) and (-3.65,-22.55) .. (-3.91,-22.66)
 .. controls (-4.17,-22.77) and (-7.05,-23.28) .. (-7.77,-23.55)
 .. controls (-8.48,-23.82) and (-8.24,-23.96) .. (-9.46,-24.19)
 .. controls (-10.68,-24.42) and (-15.54,-24.23) .. (-16.55,-24.15)
 .. controls (-17.56,-24.07) and (-24.04,-20.78) .. (-24.54,-20.61)
 .. controls (-25.03,-20.45) and (-29.39,-17.70) .. (-30.27,-17.51)
 .. controls (-31.14,-17.31) and (-34.25,-16.44) .. (-34.25,-16.44)
 -- (-37.39,-16.06)
 .. controls (-37.39,-16.06) and (-39.29,-17.69) .. (-39.60,-18.42)
 .. controls (-39.91,-19.16) and (-39.96,-26.25) .. (-40.69,-27.47)
 .. controls (-41.42,-28.68) and (-42.18,-30.27) .. (-42.97,-32.24)
 .. controls (-43.76,-34.21) and (-42.11,-39.17) .. (-42.11,-39.17)
 .. controls (-42.11,-39.17) and (-40.76,-43.08) .. (-41.26,-44.57)
 .. controls (-41.75,-46.06) and (-41.71,-48.86) .. (-41.71,-48.86)
 -- (-38.70,-49.47)
 .. controls (-38.70,-49.47) and (-34.61,-47.51) .. (-34.07,-47.04)
 .. controls (-33.52,-46.58) and (-30.27,-45.69) .. (-29.76,-45.60)
 .. controls (-29.24,-45.51) and (-23.76,-43.90) .. (-22.96,-43.45)
 .. controls (-22.16,-43.01) and (-20.42,-41.87) .. (-20.42,-41.87)
 -- (-19.37,-37.77)
 -- (-14.48,-35.48)
 .. controls (-14.48,-35.48) and (-11.88,-34.78) .. (-11.19,-35.94)
 .. controls (-10.50,-37.10) and (-9.86,-38.76) .. (-9.86,-38.76)
 -- (-7.79,-40.04)
 .. controls (-7.79,-40.04) and (-6.28,-40.02) .. (-6.32,-40.65)
 .. controls (-6.37,-41.28) and (-6.51,-41.52) .. (-6.68,-42.02)
 .. controls (-6.84,-42.51) and (-7.78,-43.33) .. (-7.96,-43.95)
 .. controls (-8.13,-44.57) and (-4.50,-48.51) .. (-4.50,-48.51)
 .. controls (-4.50,-48.51) and (-3.80,-51.10) .. (-2.29,-51.21)
 .. controls (-0.78,-51.32) and (2.99,-49.96) .. (3.54,-49.36)
 .. controls (4.09,-48.77) and (12.61,-41.45) .. (13.26,-41.25)
 .. controls (13.91,-41.05) and (13.53,-41.02) .. (14.69,-40.73)
 .. controls (15.85,-40.44) and (19.23,-39.44) .. (19.23,-39.44)
 -- (22.49,-39.95)
 .. controls (22.49,-39.95) and (25.85,-39.06) .. (26.18,-39.85)
 .. controls (26.50,-40.63) and (26.69,-41.53) .. (27.37,-42.60)
 .. controls (28.05,-43.66) and (33.14,-45.19) .. (34.84,-46.20)
 .. controls (36.54,-47.22) and (38.38,-48.11) .. (38.38,-48.11)
 .. controls (38.38,-48.11) and (41.49,-48.85) .. (42.22,-49.29)
 .. controls (42.95,-49.72) and (42.72,-49.45) .. (43.80,-50.29)
 .. controls (44.88,-51.13) and (47.20,-52.32) .. (47.20,-52.32)
 -- (48.40,-53.29)
),
1,((49.13,-50.18)
 .. controls (49.13,-50.18) and (40.57,-39.15) .. (39.72,-38.58)
 .. controls (38.88,-38.01) and (37.47,-36.39) .. (37.40,-35.62)
 .. controls (37.34,-34.85) and (38.07,-33.51) .. (37.76,-32.60)
 .. controls (37.44,-31.69) and (36.53,-30.35) .. (36.53,-30.35)
 -- (34.08,-29.16)
 -- (32.18,-25.71)
 -- (32.80,-24.24)
 .. controls (32.80,-24.24) and (33.54,-21.12) .. (33.01,-19.68)
 .. controls (32.48,-18.25) and (28.66,-11.37) .. (28.66,-11.37)
 -- (22.91,-4.99)
 -- (20.44,-2.40)
 .. controls (20.44,-2.40) and (17.79,-2.20) .. (17.48,-1.16)
 .. controls (17.18,-0.13) and (16.57,5.49) .. (15.46,5.83)
 .. controls (14.34,6.16) and (9.36,9.06) .. (9.27,9.57)
 .. controls (9.18,10.09) and (6.51,18.52) .. (6.51,18.52)
 .. controls (6.51,18.52) and (6.11,25.13) .. (6.35,26.76)
 .. controls (6.59,28.39) and (6.38,29.03) .. (6.56,29.78)
 .. controls (6.74,30.52) and (9.02,37.67) .. (9.02,37.67)
 .. controls (9.02,37.67) and (10.14,40.75) .. (10.22,41.88)
 .. controls (10.31,43.01) and (10.98,48.65) .. (10.98,48.65)
 -- (12.77,50.54)
 -- (14.52,51.93)
));
draw_downscrap;
endfig;
beginfig(3);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((13.92,53.18)
 .. controls (13.92,53.18) and (5.02,51.81) .. (3.79,51.46)
 .. controls (2.56,51.11) and (0.85,51.05) .. (0.04,51.18)
 .. controls (-0.77,51.30) and (-3.05,52.17) .. (-3.15,52.49)
 .. controls (-3.25,52.81) and (-6.35,52.80) .. (-6.67,52.76)
 .. controls (-6.99,52.72) and (-12.02,50.63) .. (-12.73,50.37)
 .. controls (-13.45,50.10) and (-15.30,49.93) .. (-16.52,49.70)
 .. controls (-17.74,49.48) and (-19.19,47.82) .. (-19.19,47.82)
 .. controls (-19.19,47.82) and (-23.00,46.78) .. (-24.02,46.73)
 .. controls (-25.03,46.68) and (-27.33,47.36) .. (-27.89,47.40)
 .. controls (-28.46,47.44) and (-31.57,48.94) .. (-32.76,49.15)
 .. controls (-33.95,49.37) and (-34.01,49.37) .. (-34.01,49.37)
 .. controls (-34.01,49.37) and (-37.74,47.75) .. (-38.21,47.34)
 .. controls (-38.69,46.94) and (-42.95,44.98) .. (-43.29,44.69)
 .. controls (-43.62,44.39) and (-45.33,41.04) .. (-46.08,40.27)
 .. controls (-46.84,39.51) and (-49.52,35.85) .. (-50.06,35.38)
 .. controls (-50.60,34.91) and (-51.31,34.78) .. (-51.59,34.29)
 .. controls (-51.88,33.81) and (-52.27,32.00) .. (-52.31,31.50)
 .. controls (-52.35,31.00) and (-48.48,24.38) .. (-47.39,23.60)
 .. controls (-46.31,22.82) and (-38.44,20.53) .. (-37.91,20.04)
 .. controls (-37.38,19.56) and (-35.77,19.00) .. (-34.93,18.36)
 .. controls (-34.09,17.73) and (-31.76,16.79) .. (-31.76,16.79)
 .. controls (-31.76,16.79) and (-26.06,20.10) .. (-25.57,20.63)
 .. controls (-25.09,21.17) and (-23.18,21.34) .. (-22.19,21.84)
 .. controls (-21.20,22.33) and (-15.94,23.27) .. (-15.28,22.78)
 .. controls (-14.61,22.29) and (-11.69,18.97) .. (-11.53,18.64)
 .. controls (-11.36,18.31) and (-6.18,14.76) .. (-5.90,14.17)
 .. controls (-5.63,13.58) and (-2.68,9.82) .. (-2.39,9.42)
 .. controls (-2.10,9.02) and (1.04,4.48) .. (1.27,4.15)
 .. controls (1.50,3.81) and (8.03,-4.65) .. (8.03,-4.65)
 .. controls (8.03,-4.65) and (10.93,-6.64) .. (11.23,-6.92)
 .. controls (11.52,-7.20) and (14.67,-11.80) .. (14.95,-12.33)
 .. controls (15.23,-12.86) and (15.84,-14.05) .. (15.84,-14.93)
 .. controls (15.84,-15.82) and (16.18,-15.59) .. (15.55,-16.30)
 .. controls (14.93,-17.00) and (14.00,-17.62) .. (13.78,-17.92)
 .. controls (13.57,-18.21) and (9.57,-18.15) .. (9.57,-18.15)
 .. controls (9.57,-18.15) and (8.21,-17.67) .. (7.92,-18.09)
 .. controls (7.64,-18.52) and (7.70,-18.52) .. (7.65,-19.21)
 .. controls (7.60,-19.91) and (8.36,-21.68) .. (8.21,-22.11)
 .. controls (8.05,-22.54) and (7.69,-23.03) .. (7.29,-23.31)
 .. controls (6.89,-23.60) and (6.04,-23.92) .. (5.46,-24.06)
 .. controls (4.88,-24.21) and (2.81,-22.85) .. (2.45,-22.57)
 .. controls (2.09,-22.30) and (0.21,-20.26) .. (0.21,-20.26)
 .. controls (0.21,-20.26) and (-0.77,-19.81) .. (-1.23,-19.97)
 .. controls (-1.69,-20.13) and (-3.65,-22.55) .. (-3.91,-22.66)
 .. controls (-4.17,-22.77) and (-7.05,-23.28) .. (-7.77,-23.55)
 .. controls (-8.48,-23.82) and (-8.24,-23.96) .. (-9.46,-24.19)
 .. controls (-10.68,-24.42) and (-15.54,-24.23) .. (-16.55,-24.15)
 .. controls (-17.56,-24.07) and (-24.04,-20.78) .. (-24.54,-20.61)
 .. controls (-25.03,-20.45) and (-29.39,-17.70) .. (-30.27,-17.51)
 .. controls (-31.14,-17.31) and (-34.25,-16.44) .. (-34.25,-16.44)
 -- (-37.39,-16.06)
 .. controls (-37.39,-16.06) and (-39.29,-17.69) .. (-39.60,-18.42)
 .. controls (-39.91,-19.16) and (-39.96,-26.25) .. (-40.69,-27.47)
 .. controls (-41.42,-28.68) and (-42.18,-30.27) .. (-42.97,-32.24)
 .. controls (-43.76,-34.21) and (-42.11,-39.17) .. (-42.11,-39.17)
 .. controls (-42.11,-39.17) and (-40.76,-43.08) .. (-41.26,-44.57)
 .. controls (-41.75,-46.06) and (-41.71,-48.86) .. (-41.71,-48.86)
 -- (-38.70,-49.47)
 .. controls (-38.70,-49.47) and (-34.61,-47.51) .. (-34.07,-47.04)
 .. controls (-33.52,-46.58) and (-30.27,-45.69) .. (-29.76,-45.60)
 .. controls (-29.24,-45.51) and (-23.76,-43.90) .. (-22.96,-43.45)
 .. controls (-22.16,-43.01) and (-20.42,-41.87) .. (-20.42,-41.87)
 -- (-19.37,-37.77)
 -- (-14.48,-35.48)
 .. controls (-14.48,-35.48) and (-11.88,-34.78) .. (-11.19,-35.94)
 .. controls (-10.50,-37.10) and (-9.86,-38.76) .. (-9.86,-38.76)
 -- (-7.79,-40.04)
 .. controls (-7.79,-40.04) and (-6.28,-40.02) .. (-6.32,-40.65)
 .. controls (-6.37,-41.28) and (-6.51,-41.52) .. (-6.68,-42.02)
 .. controls (-6.84,-42.51) and (-7.78,-43.33) .. (-7.96,-43.95)
 .. controls (-8.13,-44.57) and (-4.50,-48.51) .. (-4.50,-48.51)
 .. controls (-4.50,-48.51) and (-3.80,-51.10) .. (-2.29,-51.21)
 .. controls (-0.78,-51.32) and (2.99,-49.96) .. (3.54,-49.36)
 .. controls (4.09,-48.77) and (12.61,-41.45) .. (13.26,-41.25)
 .. controls (13.91,-41.05) and (13.53,-41.02) .. (14.69,-40.73)
 .. controls (15.85,-40.44) and (19.23,-39.44) .. (19.23,-39.44)
 -- (22.49,-39.95)
 .. controls (22.49,-39.95) and (25.85,-39.06) .. (26.18,-39.85)
 .. controls (26.50,-40.63) and (26.69,-41.53) .. (27.37,-42.60)
 .. controls (28.05,-43.66) and (33.14,-45.19) .. (34.84,-46.20)
 .. controls (36.54,-47.22) and (38.38,-48.11) .. (38.38,-48.11)
 .. controls (38.38,-48.11) and (41.49,-48.85) .. (42.22,-49.29)
 .. controls (42.95,-49.72) and (42.72,-49.45) .. (43.80,-50.29)
 .. controls (44.88,-51.13) and (47.20,-52.32) .. (47.20,-52.32)
 -- (48.40,-53.29)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((49.13,-50.18)
 .. controls (49.13,-50.18) and (40.57,-39.15) .. (39.72,-38.58)
 .. controls (38.88,-38.01) and (37.47,-36.39) .. (37.40,-35.62)
 .. controls (37.34,-34.85) and (38.07,-33.51) .. (37.76,-32.60)
 .. controls (37.44,-31.69) and (36.53,-30.35) .. (36.53,-30.35)
 -- (34.08,-29.16)
 -- (32.18,-25.71)
 -- (32.80,-24.24)
 .. controls (32.80,-24.24) and (33.54,-21.12) .. (33.01,-19.68)
 .. controls (32.48,-18.25) and (28.66,-11.37) .. (28.66,-11.37)
 -- (22.91,-4.99)
 -- (20.44,-2.40)
 .. controls (20.44,-2.40) and (17.79,-2.20) .. (17.48,-1.16)
 .. controls (17.18,-0.13) and (16.57,5.49) .. (15.46,5.83)
 .. controls (14.34,6.16) and (9.36,9.06) .. (9.27,9.57)
 .. controls (9.18,10.09) and (6.51,18.52) .. (6.51,18.52)
 .. controls (6.51,18.52) and (6.11,25.13) .. (6.35,26.76)
 .. controls (6.59,28.39) and (6.38,29.03) .. (6.56,29.78)
 .. controls (6.74,30.52) and (9.02,37.67) .. (9.02,37.67)
 .. controls (9.02,37.67) and (10.14,40.75) .. (10.22,41.88)
 .. controls (10.31,43.01) and (10.98,48.65) .. (10.98,48.65)
 -- (12.77,50.54)
 -- (14.52,51.93)
));
drawoptions();
p_narrowend((52.74,-53.81),0.0,1.00,(0,0));
drawoptions();
p_narrowend((19.06,55.03),0.0,1.00,(0,0));
ATTR__stationflag_splay := false;
drawoptions();
p_station((-39.60,-32.96),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-9.51,-26.92),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-3.78,-38.59),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((3.93,-24.99),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((29.60,-25.69),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((12.45,-0.89),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-25.26,40.85),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-5.20,45.02),1,btex \thcomment \thfb\char101 \char110 \char116 \char114 \char97 \char110 \char99 \char101 \mainfont{} etex,"");
endfig;
beginfig(4);
s_northarrow(0);
endfig;
beginfig(5);
s_scalebar(10, 1, "\thfb\char109 \mainfont{}");
endfig;
background:=(1.00000,1.00000,1.00000);
transparency:=false;
beginfig(6);
clean_legend_box;
drawoptions();
p_station_temporary((0.5,0.5) inscale);
draw_legend_box;
endfig;
beginfig(7);
clean_legend_box;
drawoptions();
l_survey_cave(((-1,1) -- (0.8,0.6) -- (0,-1)) inscale);
drawoptions(withcolor HelpSymbolColor);
p_station_temporary((0.8,0.6) inscale);
drawoptions();
draw_legend_box;
endfig;
beginfig(8);
clean_legend_box;
drawoptions();
l_wall_bedrock(((-.3,0.5) .. (.3,.3) .. (.7,.7) .. (1.3,.5)) inscale);
draw_legend_box;
endfig;
beginfig(9);
clean_legend_box;
drawoptions(withcolor HelpSymbolColor);
l_wall_bedrock(((0,.2){dir 30} .. {dir 0}(.5,.4)) inscale);
l_wall_bedrock(((.5,.6){dir 180} .. {dir 210}(0,.8)) inscale);
drawoptions();
drawoptions();
p_narrowend((.6,.5) inscale,270.0,1.0,(0,1));
draw_legend_box;
endfig;
beginfig(10);
clean_legend_box;
drawoptions();
l_floorstep((((.1,.6) .. (.5,.4) .. (.9,.6)) inscale));
draw_legend_box;
endfig;
drawoptions();
beginfig(11);
clean_legend_box;
drawoptions();
l_contour((((.1,.6) .. (.5,.4) .. (.9,.6)) inscale),-1);
draw_legend_box;
endfig;
beginfig(12);
clean_legend_box;
drawoptions();
l_rockborder(((.16,.36) -- (.61,.21) -- (.91,.46) -- (.84,.78) -- (.38,.86) -- (.20,.55) -- cycle) inscale)draw_legend_box;
endfig;
beginfig(13);
clean_legend_box;
l_u_texture_MY_legend;
draw_legend_box;
endfig;
end;
