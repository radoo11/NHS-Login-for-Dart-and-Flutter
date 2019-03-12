library nhs_authentication;

import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';
import 'package:nhs_login/src/models/authentication/nhs_display.dart';
import 'package:nhs_login/src/models/authentication/nhs_prompt.dart';
import 'package:nhs_login/src/models/authentication/nhs_scope.dart';
import 'package:nhs_login/src/models/authentication/nhs_vector_or_trust.dart';
import 'package:nhs_login/src/models/serializers.dart';

part 'nhs_authentication.g.dart';

/// The client initiates an authentication request to the NHS Digital NHS login
/// authorize endpoint using the HTTP GET or POST methods.
///
/// If using HTTP GET, then the parameters are serialised using URI query
/// Serialisation. In the case of HTTP POST, then the parameters are serialised
/// using Form Serialisation
abstract class NhsAuthentication
    implements Built<NhsAuthentication, NhsAuthenticationBuilder> {
  factory NhsAuthentication([void updates(NhsAuthenticationBuilder b)]) {
    return _$NhsAuthentication((b) {
      b
        ..responseType = 'code'
        ..update(updates);
    });
  }

  factory NhsAuthentication.fromJson(Map<String, dynamic> json) =>
      serializers.deserializeWith(serializer, json);

  factory NhsAuthentication.fromValues({
    @required List<NhsScope> scopes,
    String host,
    String clientId,
    String redirectUri,
    String state,
    String nonce,
    NhsDisplay display = NhsDisplay.page,
    NhsPrompt prompt,
    NhsVectorOfTrust vectorOfTrust,
    String fidoAuthResponse,
    String assertedLoginIdentity,
    bool allowRegistration,
  }) {
    assert(scopes.isNotEmpty && scopes.contains(NhsScope.openId));
    state ??= _randomString();
    nonce ??= _randomString();

    return NhsAuthentication((NhsAuthenticationBuilder b) {
      b
        ..responseType = 'code'
        ..scopes = ListBuilder<NhsScope>(scopes)
        ..host = host
        ..clientId = clientId
        ..redirectUri = redirectUri
        ..state = state
        ..nonce = nonce
        ..display = display
        ..prompt = prompt
        ..vectorOfTrust = vectorOfTrust
        ..fidoAuthResponse = fidoAuthResponse
        ..assertedLoginIdentity = assertedLoginIdentity
        ..allowRegistration = allowRegistration;
    });
  }

  NhsAuthentication._();

  String get responseType;

  /// The host of the NHS Server
  String get host;

  /// Request that specific sets of information be made available as Claim
  /// Values when making an Authentication Request
  BuiltList<NhsScope> get scopes;

  /// OAuth 2.0 Client Identifier
  ///
  /// This is a static identifier previously provided by the NHS login Partner
  /// Onboarding team
  String get clientId;

  /// Redirection URI to which the response will be sent.
  ///
  /// This URI MUST exactly match one of the Redirection URI values for the
  /// Client pre-registered at the OpenID Provider. When using this flow,
  /// the Redirection URI MUST NOT use the http scheme. The Redirection URI MAY
  /// use an alternate scheme, such as one that is intended to identify a
  /// callback into a native application
  String get redirectUri;

  /// Opaque value used to maintain state between the request and the callback.
  ///
  /// Typically, Cross-Site Request Forgery (CSRF, XSRF) mitigation is done by
  /// cryptographically binding the value of this parameter with a browser
  /// cookie.
  ///
  /// This value will be returned to the client in the authentication response.
  /// The iGov profile for OIDC specifies this parameter as Mandatory to help
  /// RPs protect against CSRF attacks.
  String get state;

  /// String value used to associate a Client session with an ID Token, and to
  /// mitigate replay attacks.
  ///
  /// The value is passed through unmodified from the
  /// Authentication Request to the ID Token. Sufficient entropy MUST be present
  /// in the nonce values used to prevent attackers from guessing values. The
  /// iGov profile for OIDC specifies this parameter as Mandatory to help RPs
  /// protect against CSRF attacks.
  String get nonce;

  /// Specifies how the Platform displays the authentication and consent user
  /// interface pages to the End-User.
  ///
  /// NOTE: [NhsDisplay.popup] and [NhsDisplay.wap] values are not supported
  @nullable
  NhsDisplay get display;

  /// Requests that the NHS login Service forces the user to sign-in, or to
  /// request that the Service does not prompt the user to sign-in (SSO)
  @nullable
  NhsPrompt get prompt;

  /// Vector of Trust Request – requested levels of Identity Verification and
  /// Authentication.
  ///
  /// Defaults to "["P9.Cp.Cd","P9.Cp.Ck","P9.Cm"]" being assumed
  @nullable
  NhsVectorOfTrust get vectorOfTrust;

  /// Base64 URL-encoded FIDO UAF AuthResponse message generated by FIDO client
  /// on a registered device
  @nullable
  String get fidoAuthResponse;

  /// The purpose of this parameter is to support seamless login between two RPs
  /// (RP1 and RP2) where cookie-based SSO is not available. The content will be
  /// a signed jwt with payload containing "code" attribute with the value being
  /// that of the "jti" attribute from the ID Token issued to RP1. The jwt "iss"
  /// attribute MUST contain the client_id of RP1, the jwt MUST have an "exp" of
  /// no longer that 60 seconds, MUST have "jti" and "iat" attributes
  /// (as per RFC7519) and MUST be signed by RP1 using its client private key.
  /// RP1 passes the jwt to RP2 for RP2 to use in its authentication request.
  ///
  /// A non-normative example jwt payload section is as follows
  /// ```json
  /// {
  ///   "code": "eeroifoteiwrudjdwusdu",
  ///   "iss": "client1",
  ///   "jti": "reioteotijdvorijevoihroi",
  ///   "iat": 1548701645,
  ///   "exp": 1548701705
  /// }
  /// ```
  @nullable
  String get assertedLoginIdentity;

  /// If [false], will hide links to account registration screens in the NHS
  /// login UI.
  @nullable
  bool get allowRegistration;

  Uri get uri {
    assert(host != null && host.isNotEmpty);

    return Uri(
      scheme: 'https',
      host: host,
      path: 'authorize',
      queryParameters: _params,
    );
  }

  Map<String, dynamic> get _params {
    assert(clientId != null && clientId.isNotEmpty);
    assert(redirectUri != null && redirectUri.isNotEmpty);
    assert(state != null && state.isNotEmpty);
    assert(nonce != null && nonce.isNotEmpty);

    final Map<String, dynamic> params = <String, dynamic>{
      'scope': scopes.join(' '),
      'response_type': responseType,
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'state': state,
      'nonce': nonce,
    };

    if (display != null) {
      params['display'] = display.name;
    }

    if (prompt != null) {
      params['prompt'] = prompt.value;
    }

    if (vectorOfTrust != null) {
      params['vtr'] = vectorOfTrust.toString();
    }

    if (fidoAuthResponse != null) {
      params['fido_auth_response'] = fidoAuthResponse;
    }

    if (assertedLoginIdentity != null) {
      params['asserted_login_identity'] = assertedLoginIdentity;
    }

    if (allowRegistration != null) {
      params['allow_registration'] = allowRegistration.toString();
    }

    return params;
  }

  @memoized
  Map<String, dynamic> get json => serializers.serializeWith(serializer, this);

  static Serializer<NhsAuthentication> get serializer =>
      _$nhsAuthenticationSerializer;

  static Serializer<NhsAuthentication> get $serializer =>
      _nhsTokenResponseSerializer;
}

Serializer<NhsAuthentication> _nhsTokenResponseSerializer =
    _NhsAuthenticationSerializer();

class _NhsAuthenticationSerializer extends _$NhsAuthenticationSerializer {
  @override
  Iterable serialize(Serializers serializers, NhsAuthentication object,
      {FullType specifiedType = FullType.unspecified}) {
    final List result = super.serialize(serializers, object);

    result[result.indexOf('scopes') + 1] = serializers.serialize(
        object.scopes.join(' '),
        specifiedType: const FullType(String));

    return result;
  }

  @override
  NhsAuthentication deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new NhsAuthenticationBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'responseType':
          result.responseType = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'host':
          result.host = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'scopes':
          result.scopes.replace(serializers.deserialize(value.split(' '),
              specifiedType: const FullType(
                  BuiltList, const [const FullType(NhsScope)])) as BuiltList);
          break;
        case 'clientId':
          result.clientId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'redirectUri':
          result.redirectUri = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'state':
          result.state = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'nonce':
          result.nonce = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'display':
          result.display = serializers.deserialize(value,
              specifiedType: const FullType(NhsDisplay)) as NhsDisplay;
          break;
        case 'prompt':
          result.prompt = serializers.deserialize(value,
              specifiedType: const FullType(NhsPrompt)) as NhsPrompt;
          break;
        case 'vectorOfTrust':
          result.vectorOfTrust = serializers.deserialize(value,
                  specifiedType: const FullType(NhsVectorOfTrust))
              as NhsVectorOfTrust;
          break;
        case 'fidoAuthResponse':
          result.fidoAuthResponse = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'assertedLoginIdentity':
          result.assertedLoginIdentity = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'allowRegistration':
          result.allowRegistration = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
      }
    }

    return result.build();
  }
}

String _randomString() {
  final Random r = Random.secure();
  final List<int> chars =
      '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
          .codeUnits;
  final Iterable<int> result =
      Iterable<int>.generate(50, (_) => chars[r.nextInt(chars.length)]);
  return String.fromCharCodes(result);
}
