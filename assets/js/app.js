import css from "../css/app.css"

import "phoenix_html"

// We need this polyfill to support drag and drop on iOS.
// Safari is the new IE :(
import {polyfill} from "mobile-drag-drop";
import {scrollBehaviourDragImageTranslateOverride} from "mobile-drag-drop/scroll-behaviour";

import LiveSocket from "phoenix_live_view"

let liveSocket = new LiveSocket("/live")
liveSocket.connect()

// init the pollyfill for Safari/iOS
polyfill({
  dragImageTranslateOverride: scrollBehaviourDragImageTranslateOverride
});


// On the initial page load, we hook up our event listeners to parent DIV
// of all the boards & tickets. This is unobtrusive way, and allows LiveView
// to re-render the underlying HTML without the need for us to re-bind event
// listeners when HTML changes.
const init = function() {
  let currentTicketHeight = 0;

  // When user starts to drag a ticket, we hide it on the original board
  // and take a note of ticket ID in the dataTransfer struct.
  document.querySelector(".boards").addEventListener("dragstart", (e) => {
    if (e.target.classList.contains("ticket-title")) {
      e.stopPropagation();

      currentTicketHeight = e.target.offsetHeight;

      e.dataTransfer.effectAllowed = 'move';
      e.dataTransfer.setData('text/plain', e.target.getAttribute("data-ticket-id"));

      setTimeout(function() { e.target.parentNode.style.display = 'none' }, 0);
    }
  });

  // I'm not sure if we needthis
  // TODO: possibly remove
  document.querySelector(".boards").addEventListener("dragover", (e) => {
    if (e.preventDefault)
      e.preventDefault() // allows to drop

    e.dataTransfer.dropEffect = 'move';
    return false;
  });

  // Whenever you drop a ticket, send a custom LiveView event
  // which will be handled on the server-side. We find where the
  // ticket has been dropped, we fint it's parent LiveView, and
  // assemble custom event with ticket_id and where it has been
  // dropped.
  // We do nothing more, once the event is done processing on the
  // server, our LiveView will update on it's own with ticket on
  // new position.
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

  // helper, just make sure only one node is selected to drop the ticket onto
  const deselectAll = function(selector, exceptNode) {
    const otherNodes = Array.prototype.slice.call(document.querySelectorAll(selector));

    otherNodes.map((node) => {
      if (!!exceptNode || node !== exceptNode) {
        node.classList.remove("over");
      }
    });
  }

  // make sure our placeholder (.drop-ghost) have the same height as the
  // ticket I am currently dragging, so the whole thing does not flicker when
  // we drop the ticket.
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

  // Whenever we drag a ticket over another ticket we open it's "ghost" drop
  // zone.
  // Whenever we drag a ticket over a column but not a ticket, we open column
  // "ghost" drop zone that is at the end of the list of all tickets.
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

  // For iOS not to go crazy, required by pollyfill.
  window.addEventListener( 'touchmove', function() {});
};

window.addEventListener("load", init);


