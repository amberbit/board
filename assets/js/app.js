// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"

//import "./DragDropTouch";

import {polyfill} from "mobile-drag-drop";

import {scrollBehaviourDragImageTranslateOverride} from "mobile-drag-drop/scroll-behaviour";

import LiveSocket from "phoenix_live_view"

let liveSocket = new LiveSocket("/live")
liveSocket.connect()

polyfill({
       dragImageTranslateOverride: scrollBehaviourDragImageTranslateOverride
});

const init = function() {
  let currentTicketHeight = 0;

  document.querySelector(".boards").addEventListener("dragstart", (e) => {
    if (e.target.classList.contains("ticket-title")) {
      e.stopPropagation();

      currentTicketHeight = e.target.offsetHeight;

      e.dataTransfer.effectAllowed = 'move';
      e.dataTransfer.setData('text/plain', e.target.getAttribute("data-ticket-id"));
      //e.target.classList.add("pop");

      setTimeout(function() { e.target.parentNode.style.display = 'none' }, 0);
    }
  });

  document.querySelector(".boards").addEventListener("dragover", (e) => {
    if (e.preventDefault)
      e.preventDefault() // allows to drop

    e.dataTransfer.dropEffect = 'move';
    return false;
  });

  document.querySelector(".boards").addEventListener("drop", (e) => {
    const ticket_id = e.dataTransfer.getData('text/plain');
    const column_id = document.querySelector(".over").closest(".board-column").getAttribute("data-column-id");

    let before_ticket_id = null;

    if (document.querySelector(".over").classList.contains("ticket")) {
      before_ticket_id = document.querySelector(".over").getAttribute("data-ticket-id");
      const target = document.querySelector(".over").closest("[data-phx-view]")
      const phxEvent = {"ticket_id": ticket_id, "column_id": column_id, "before_ticket_id": before_ticket_id}
      liveSocket.owner(target, view => view.pushEvent("drop", target, phxEvent))
    } else {
      before_ticket_id = document.querySelector(".over").getAttribute("data-ticket-id");
      const target = document.querySelector(".over").closest("[data-phx-view]")
      const phxEvent = {"ticket_id": ticket_id, "column_id": column_id, "before_ticket_id": before_ticket_id}
      liveSocket.owner(target, view => view.pushEvent("drop", target, phxEvent))
    }
  });

  const deselectAll = function(selector, exceptNode) {
    const otherNodes = Array.prototype.slice.call(document.querySelectorAll(selector));

    otherNodes.map((node) => {
      if (!!exceptNode || node !== exceptNode) {
        node.classList.remove("over");
      }
    });
  }

  const adjustGhostHeights = function() {
    const currentGhost = document.querySelector(".over > .drop-ghost");
    const ghosts = Array.prototype.slice.call(document.querySelectorAll(".drop-ghost"));

    ghosts.map((node) => {
      if (currentGhost && currentGhost === node) {
        node.style.height = currentTicketHeight + "px";
      } else {
        node.style.height = 0;
      }
    });
  }

  document.querySelector(".boards").addEventListener("dragenter", (e) => {
    e.preventDefault();
    if (e.target.classList.contains("ticket")) {
      deselectAll(".ticket.over", e.target);
      deselectAll(".board-tickets.over");
      e.target.classList.add("over");
    } else if (e.target.classList.contains("board-tickets")) {
      deselectAll(".ticket.over");
      deselectAll(".board-tickets.over", e.target);
      e.target.classList.add("over");
    }

    adjustGhostHeights();
  });

  window.addEventListener( 'touchmove', function() {});

};

window.addEventListener("load", init);


