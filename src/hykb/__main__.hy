(import hy *) ;; Import all hy functions
(import hyrule *) ;; Import all hyrule helper functions
(require hyrule *) ;; Import all hyrule macros

;; (import atexit)
;; (import evdev)
(import 
  sys
  os 
  pathlib [Path] 
  shutil)

(import hykb [common])

(setv conf-prefix
  (/ (Path 
       (cond 
         [(in "XDG_CONFIG_HOME" os.environ) (get os.environ "XDG_CONFIG_HOME")]
         [:else "~/.config"]))
     "hykb"))

(setv app-prefix
  (Path (os.path.dirname (os.path.realpath __file__))))
    
(defmain [#* args]
  (. conf-prefix (mkdir :parents True :exist-ok True))
  (let [conf (/ conf-prefix "config.hy")]
    (when (not (conf.is_file))
      (print "Config not detected, trying to create new config at:" conf)
      (let [default-conf (/ app-prefix "examples" "config.hy")]
        (shutil.copy default-conf conf)))
    (print "Starting hykb...") 
    (sys.path.append (str conf-prefix))
    (import config)))
  
;; A translation of https://gist.github.com/t184256/f4994037a2a204774ef3b9a2b38736dc
'(defmain [#* args]
  (let [remap-table
        {evdev.ecodes.KEY-A evdev.ecodes.KEY-B
         evdev.ecodes.KEY-B evdev.ecodes.KEY-A}
        kbd 
        (->>
          (lfor 
           i (evdev.list-devices) 
           (evdev.InputDevice i))
          (filter (fn [x] (= x.name "AT Translated Set 2 keyboard")))
          next)]
   (atexit.register kbd.ungrab)
   (kbd.grab)
   (with [ui (evdev.UInput.from-device kbd :name "kbdremap")]
     (for [ev (kbd.read-loop)]
       (if (and (= ev.type evdev.ecodes.EV-KEY)
                (in ev.code remap-table))
         (let [remapped (get remap-table ev.code)]
           (ui.write evdev.ecodes.EV-KEY remapped ev.value))
         (ui.write ev.type ev.code ev.value))))))
