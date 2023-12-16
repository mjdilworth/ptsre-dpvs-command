package api

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestHealth(t *testing.T) {
	wr := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/health", nil)

	Health(wr, req)
	if wr.Code != http.StatusOK {
		t.Errorf("got HTTP status code %d, expected 200", wr.Code)
	}

	if !strings.Contains(wr.Body.String(), "I am healthy") {
		t.Errorf(
			`response body "%s" does not contain "I am healthy"`,
			wr.Body.String(),
		)
	}
}

func TestAuth(t *testing.T) {
	wr := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/secret", nil)

	Auth(wr, req)
	if wr.Code != http.StatusOK {
		t.Errorf("got HTTP status code %d, expected 200", wr.Code)
	}

	if !strings.Contains(wr.Body.String(), "You get to see the secret") {
		t.Errorf(
			`response body "%s" does not contain "You get to see the secret"`,
			wr.Body.String(),
		)
	}
}

// The test to ensure we get a 401 if no username and pass give
func TestAuthFail(t *testing.T) {
	wr := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/secret", nil)

	Auth(wr, req)
	if wr.Code != http.StatusUnauthorized {
		t.Errorf("got HTTP status code %d, expected 401", wr.Code)
	}
}
func TestRoot(t *testing.T) {
	wr := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/", nil)

	Root(wr, req)
	if wr.Code != http.StatusOK {
		t.Errorf("got HTTP status code %d, expected 200", wr.Code)
	}

	if !strings.Contains(wr.Body.String(), "HTTP Served by GO") {
		t.Errorf(
			`response body "%s" does not contain "HTTP Served by GO"`,
			wr.Body.String(),
		)
	}
}

func TestVerifyUserPass(t *testing.T) {

	//table driven test
	var tests = []struct {
		a string
		b string
		c bool
	}{
		{"user1", "pass1", true},
		{"user2", "pass2", true},
	}

	for _, test := range tests {
		want := test.c
		if got := verifyUserPass(test.a, test.b); got != want {
			t.Errorf("verifyUserPass() = %t, want %t", got, want)
		}

	}
}
