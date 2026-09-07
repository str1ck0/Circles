import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="map"
export default class extends Controller {
  static values = {
    apiKey: String,
    markers: Array,
  };

  connect() {
    if (!this.apiKeyValue || this.markersValue.length === 0) return;

    mapboxgl.accessToken = this.apiKeyValue;

    this.map = new mapboxgl.Map({
      container: this.element,
      style: 'mapbox://styles/hamburgsabi/clacj62l8007u14ozlxpqh4pb',
    });

    this.#addMarkersToMap();
    this.#fitMapToMarkers();
  }

  disconnect() {
    if (this.map) this.map.remove();
  }

  #addMarkersToMap() {
    this.markersValue.forEach((marker) => {
      new mapboxgl.Marker({ color: '#ff9d00' }).setLngLat([marker.lng, marker.lat]).addTo(this.map);
    });
  }

  #fitMapToMarkers() {
    const bounds = new mapboxgl.LngLatBounds();
    this.markersValue.forEach((marker) => bounds.extend([marker.lng, marker.lat]));
    this.map.fitBounds(bounds, { padding: 60, maxZoom: 14, duration: 0 });
  }
}
