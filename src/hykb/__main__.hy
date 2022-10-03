(import hy *) ;; Import all hy functions
(import hyrule *) ;; Import all hyrule helper functions
(require hyrule *) ;; Import all hyrule macros

(import atexit)
(import evdev)

;; A translation of https://gist.github.com/t184256/f4994037a2a204774ef3b9a2b38736dc
(defmain [#* args]
  (let [remap-table
        {evdev.ecodes.KEY_A evdev.ecodes.KEY_B
         evdev.ecodes.KEY_B evdev.ecodes.KEY_A}
        kbd 
        (->>
          (lfor 
           i (evdev.list_devices) 
           (evdev.InputDevice i))
          (filter (fn [x] (= x.name "AT Translated Set 2 keyboard")))
          next)]
   (atexit.register kbd.ungrab)
   (kbd.grab)
   (with [ui (evdev.UInput.from_device kbd :name "kbdremap")]
     (for [ev (kbd.read_loop)]
       (if (and (= ev.type evdev.ecodes.EV_KEY)
                (in ev.code remap-table))
         (let [remapped (get remap-table ev.code)]
           (print "MAPPING" ev.code "TO" remapped)
           (ui.write evdev.ecodes.EV_KEY remapped ev.value))
         (ui.write ev.type ev.code ev.value))))))
